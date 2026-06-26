# AI 动漫头像服务

基于 Stable Diffusion + ControlNet(depth) + LoRA 的人脸动漫化 API，部署在双 NVIDIA 3090 GPU 上。

## 架构

```
用户照片 → Mediapipe 人脸检测 → 裁剪 512x512
                                    ↓
                              MiDaS 深度图提取
                                    ↓
                     SD1.5 + ControlNet(depth) + 动漫LoRA
                                    ↓
                          动漫风格头像 (512x512 PNG)
```

```
                    ┌──────────────────┐
                    │  Nginx :8200     │
                    │  (负载均衡)       │
                    └────┬───────┬─────┘
                         │       │
              ┌──────────▼┐   ┌──▼──────────┐
              │ Worker-0   │   │ Worker-1    │
              │ GPU 0      │   │ GPU 1       │
              │ 3090       │   │ 3090        │
              │ SD+CN+LoRA │   │ SD+CN+LoRA  │
              └────────────┘   └─────────────┘
```

## 快速部署

### 1. 预下载模型（可选但推荐）

```bash
cd ai-service
python3 download_models.py
```

### 2. 构建并启动

```bash
cd ai-service
docker compose up -d --build
```

首次构建约 10-15 分钟（下载 PyTorch + 模型）。启动后每个 worker 约 30 秒加载模型。

### 3. 验证

```bash
# 负载均衡器健康检查
curl http://localhost:8200/health

# 测试动漫化
python3 -c "
import base64, requests
img = base64.b64encode(open('test_face.jpg','rb').read()).decode()
r = requests.post('http://localhost:8200/api/anime-face', json={'image_base64': img})
print(r.json()['success'], r.json()['elapsed_ms'], 'ms')
"
```

## API 接口

### POST /api/anime-face

请求：
```json
{
  "image_base64": "<base64编码的人脸照片>",
  "prompt": "",                    // 可选，默认动漫风格
  "negative_prompt": "",           // 可选
  "num_inference_steps": 30,       // 1-100，越大越精细越慢
  "guidance_scale": 7.0,           // 1-20，CFG引导强度
  "controlnet_conditioning_scale": 0.8,  // 0-2，深度图控制强度
  "seed": -1                       // -1 随机
}
```

响应：
```json
{
  "success": true,
  "image_base64": "<base64编码的动漫头像PNG>",
  "error": "",
  "elapsed_ms": 3500
}
```

## 模型配置

通过环境变量自定义模型：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `SD_BASE_MODEL` | `runwayml/stable-diffusion-v1-5` | SD 基础模型 |
| `CONTROLNET_MODEL` | `lllyasviel/control_v11f1p_sd15_depth` | ControlNet 模型 |
| `LORA_PATH` | (空) | LoRA 权重路径或 HF repo |
| `LORA_SCALE` | `0.8` | LoRA 强度 0-1 |

### 使用动漫风格 LoRA

```yaml
# docker-compose.yml 中设置
environment:
  - LORA_PATH=/app/models/my_anime_lora.safetensors
```

或使用 HuggingFace 上的 LoRA：
```yaml
environment:
  - LORA_PATH=Ojimi/anime-portrait-lora
```

## 性能参考 (单卡 3090, fp16)

| 步数 | 推理时间 | 显存占用 |
|------|---------|---------|
| 20 steps | ~1.5s | ~6GB |
| 30 steps | ~2.5s | ~6GB |
| 50 steps | ~4s | ~6GB |

双卡并行吞吐量：约 40-80 张/分钟（取决于步数）。
