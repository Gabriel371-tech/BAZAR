import json
import ssl
import urllib.request

binId = '69e957d2856a682189614c23'
apikey = '$2a$10$sV.w2uJ6HwkguXs2vwUM4u15GSm0E5DTYrU3f35WeRaWAA2Z2tGEO'
url = f'https://api.jsonbin.io/v3/b/{binId}/latest'
req = urllib.request.Request(url, headers={'X-Master-Key': apikey, 'Content-Type': 'application/json'})
context = ssl._create_unverified_context()
with urllib.request.urlopen(req, context=context, timeout=30) as resp:
    data = resp.read().decode('utf-8')
    print('status', resp.status)
    print(data)
