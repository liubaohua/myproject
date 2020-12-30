#pip install pyttsx3
#pip install SpeechRecognition

import speech_recognition as sr
import logging
logging.basicConfig(level=logging.DEBUG)





import speech_recognition as sr
import sys

say = '你看看'
r = sr.Recognizer()

# 本地语音测试
harvard = sr.AudioFile(sys.path[0]+'/TALK101.wav')
with harvard as source:
    # 去噪
    r.adjust_for_ambient_noise(source, duration=0.2)
    audio = r.record(source)

# 语音识别
test = r.recognize_google(audio, language="cmn-Hans-CN", show_all=True)
print(test)

# 分析语音
flag = False
for t in test['alternative']:
    print(t)
    if say in t['transcript']:
        flag = True
        break
if flag:
    print('Bingo')



while True:
    r = sr.Recognizer()
    # 麦克风
    mic = sr.Microphone()

    logging.info('录音中...')
    with mic as source:
        r.adjust_for_ambient_noise(source)
        audio = r.listen(source)
    logging.info('录音结束，识别中...')
    test = r.recognize_google(audio, language='cmn-Hans-CN', show_all=True)
    print(test)
    logging.info('end')



import pyttsx3
engine = pyttsx3.init()
engine.say("Hello world")
engine.runAndWait()


import win32com.client as win
speak = win.Dispatch("SAPI.SpVoice")
speak.Speak("come on")
speak.Speak("你好")

