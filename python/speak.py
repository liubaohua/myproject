import win32com.client as win
import sys
from win32com.client import constants
import win32com.client

speaker = win.Dispatch("SAPI.SPVOICE")
s = input()
speaker.Speak(s) #一个一个字母朗读
#win.Dispatch("Excel.Application")
