import datetime as dt
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import threading,socket
from random import random
# Create figure for plotting temp_c
fig = plt.figure()
ax = fig.add_subplot(1, 1, 1)
xs = []
ys = []
inc=0
def main():
    global xs,ys,inc
    s=socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.bind(("192.168.0.100", 80))
    s.listen()
    while 1:
        try:
            conn, addr = s.accept()
            print('Connected by', addr)
            request=conn.recv(1024).decode()
            request=request[request.find("GET")+5:request.find("HTTP/1.1")]
            print(request)
            request=float(request)
            print(request)
            conn.send(b'HTTP/1.0 200 OK\r\n')
            conn.send(b"Content-Type: text/html\r\n\r\n")
            conn.send(b'<html><body><h1>Hello World</body></html>')
            conn.close()

            # Add x and y to lists
            xs.append(inc)
            ys.append(request)
            inc+=1
        except ValueError:
            pass



def fff(i, xs, ys):
    # Limit x and y lists
    xs = xs[-500:]
    ys = ys[-500:]
    # Format plot
    ax.clear()
    ax.plot(xs, ys)

    plt.xticks(rotation=45, ha='right')
    plt.title(ys[-1:])
    plt.subplots_adjust(bottom=0.30)
    plt.ylabel('RPM')

threading.Thread(target=main).start()
# Set up plot to call animate() function periodically
ani = animation.FuncAnimation(fig, fff, fargs=(xs, ys), interval=100)
plt.show()
