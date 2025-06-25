#!/usr/bin/env python3
"""
简化的 Telegram Bot 推送脚本
使用 Bot API，只需要 BOT_TOKEN 和 CHAT_ID
"""

import os
import sys
import requests
from pathlib import Path


def get_env_var(name, required=True):
    """获取环境变量"""
    value = os.environ.get(name)
    if required and not value:
        print(f"❌ 错误: 缺少必需的环境变量 {name}")
        sys.exit(1)
    return value


def get_caption():
    """生成消息标题"""
    version = os.environ.get("VERSION", "unknown")
    commit = os.environ.get("COMMIT", "Manual build")

    template = """
{version}

{commit}

🔗 [GitHub](https://github.com/taamarin/box_for_magisk)
📦 [Releases](https://github.com/taamarin/box_for_magisk/releases)

#BoxForRoot #Magisk #KernelSU #APatch #module
""".strip()

    msg = template.format(version=version, commit=commit)

    # Telegram 消息长度限制
    if len(msg) > 1024:
        return f"{version}\n\n{commit}"

    return msg


def send_to_telegram(files):
    """发送文件到 Telegram Bot"""
    # 获取配置
    bot_token = get_env_var("BOT_TOKEN")
    chat_id = get_env_var("CHAT_ID")

    print(f"📱 连接到 Telegram Bot...")
    print(f"   Bot Token: {bot_token[:10]}...")
    print(f"   Chat ID: {chat_id}")

    # Telegram Bot API 基础 URL
    base_url = f"https://api.telegram.org/bot{bot_token}"

    for i, file_path in enumerate(files):
        print(f"📤 发送文件 {i+1}/{len(files)}: {file_path}")

        # 准备文件和消息
        with open(file_path, 'rb') as file:
            files_data = {'document': file}

            # 只在最后一个文件添加标题
            caption = get_caption() if i == len(files) - 1 else ""

            data = {
                'chat_id': chat_id,
                'caption': caption,
                'parse_mode': 'Markdown'
            }

            try:
                # 发送文件
                response = requests.post(
                    f"{base_url}/sendDocument",
                    files=files_data,
                    data=data,
                    timeout=60
                )

                if response.status_code == 200:
                    result = response.json()
                    if result.get('ok'):
                        print(f"✅ 文件 {i+1} 发送成功!")
                    else:
                        print(f"❌ 文件 {i+1} 发送失败: {result.get('description', 'Unknown error')}")
                        sys.exit(1)
                else:
                    print(f"❌ HTTP 错误 {response.status_code}: {response.text}")
                    sys.exit(1)

            except requests.exceptions.RequestException as e:
                print(f"❌ 网络错误: {e}")
                sys.exit(1)
            except Exception as e:
                print(f"❌ 发送失败: {e}")
                sys.exit(1)

    print("✅ 所有文件发送成功!")


def main():
    """主函数"""
    print("🚀 Telegram Bot 推送工具")
    print("=" * 50)

    # 检查参数
    if len(sys.argv) < 2:
        print("❌ 错误: 请提供要发送的文件路径")
        print("用法: python3 telegram_push.py <file1> [file2] ...")
        sys.exit(1)

    # 获取文件列表
    files = sys.argv[1:]
    valid_files = []

    for file_path in files:
        if os.path.isfile(file_path):
            valid_files.append(file_path)
            print(f"📁 找到文件: {file_path}")
        else:
            print(f"⚠️  警告: 文件不存在: {file_path}")

    if not valid_files:
        print("❌ 错误: 没有找到有效的文件")
        sys.exit(1)

    # 检查环境变量（只需要 BOT_TOKEN 和 CHAT_ID）
    required_vars = ["BOT_TOKEN", "CHAT_ID"]
    missing_vars = []

    for var in required_vars:
        if not os.environ.get(var):
            missing_vars.append(var)

    if missing_vars:
        print("❌ 错误: 缺少以下环境变量:")
        for var in missing_vars:
            print(f"   - {var}")
        print("\n请在 GitHub Secrets 中设置这些变量")
        sys.exit(1)

    # 显示配置信息
    print(f"🔧 配置信息:")
    print(f"   Chat ID: {os.environ.get('CHAT_ID')}")
    print(f"   文件数量: {len(valid_files)}")

    # 发送文件
    try:
        send_to_telegram(valid_files)
    except KeyboardInterrupt:
        print("\n⚠️  操作被用户取消")
        sys.exit(1)
    except Exception as e:
        print(f"❌ 发送过程中出现错误: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
