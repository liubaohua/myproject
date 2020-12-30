# pip install numpy
import logging
logging.basicConfig(level=logging.WARN)
logging.warn('录音中...')
logging.error('录音中...')
logging.info('录音中...')
logging.debug('录音中...')

import speech_recognition as sr
r = sr.Recognizer()
#mic = sr.Microphone()
resource = {
    r"(你看看?){1}.*\1": "我不看，再让我看打死你",
    r"(你看看?)+": "你看看你看看，操不操心",
    r"(你.+啥)+": "咋地啦",
    r"(六六六|666)+": "要不说磐石老弟六六六呢？",
    r"(磐|石|老|弟)+": "六六六",
}

for s,d in resource.items():
 logging.error(s)
 logging.error(d)


logging.error(s)
logging.error(d)


import numpy

speed = [99,86,87,88,111,86,103,87,94,78,77,85,86]

x = numpy.mean(speed)

print(x)

import numpy 

arr = numpy.array([1, 2, 3, 4, 5]) 

print(arr)

import numpy as np 

arr = np.array([1, 2, 3, 4, 5]) 

print(arr)

import numpy as np

print(np.__version__)

import numpy as np

arr = np.array([[[1, 2, 3], [4, 5, 6]], [[1, 2, 3], [4, 5, 6]]])

logging.error(arr)