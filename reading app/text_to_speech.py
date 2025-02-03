from gtts import gTTS
import os

try:
    # 打印当前工作目录
    print(f"当前工作目录: {os.getcwd()}")
    
    text = "你好，这是文字转语音的示例"
    tts = gTTS(text, lang='zh-cn')
    
    # 尝试保存文件
    output_path = "output.mp3"
    tts.save(output_path)
    
    # 检查文件是否成功创建
    if os.path.exists(output_path):
        print(f"文件成功保存在: {os.path.abspath(output_path)}")
    else:
        print("文件未能成功创建")
        
except Exception as e:
    print(f"发生错误: {str(e)}")