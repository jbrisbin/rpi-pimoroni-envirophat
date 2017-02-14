# Pimoroni Enviro pHAT Docker Image

Herein lies the `Dockerfile` needed to build a Docker image suitable for running Python 3 scripts using the [Pimoroni Enviro pHAT module](https://shop.pimoroni.com/products/enviro-phat) for the Raspberry Pi.

* [GitHub Repository](https://github.com/jbrisbin/rpi-pimoroni-envirophat)
* [Dockerfile](https://github.com/jbrisbin/rpi-pimoroni-envirophat/blob/master/Dockerfile)

### Pre-requisites

Installing [HypriotOS](https://blog.hypriot.com/getting-started-with-docker-on-your-arm-device/) on your Raspberry Pi using the [flash utility](https://github.com/hypriot/flash) and installing an image from the [hypriot releases page](https://github.com/hypriot/image-builder-rpi/releases) is a recommneded way to get your Pi ready to read data from your Enviro pHAT using Docker and Python. These instructions assume you're running at least version 1.2.0 of HypriotOS (which includes Docker 1.13) and that you'll be using Python 3. 

_Note: You can also use a bare-bones Raspbian and install Docker separately._

### Set up I2C

To use this Docker image, you need to ensure that the Pi is configured for I2C. That can be accomplished fairly easily by ensuring that `libffi-dev` and `i2c-tools` are installed.

```sh
sudo apt-get install -y libffi-dev i2c-tools
```

You also need to update a couple files on the Pi to ensure the kernel modules are loaded to enable I2C.

```sh
cat <<END >>/etc/modules
i2c-bcm2708
i2c-dev
END

cat <<END >>/boot/config.txt
dtparam=i2c1=on
dtparam=i2c_arm=on
END
```

Once you reboot your Pi, you should have I2C working. You can verify that the Pi sees your I2C bus by using the `i2cdetect` utility.

```sh
sudo i2cdetect -l
```

You should see the output of that command list your I2C bus.

### Create the Docker Image

Once you're sure that I2C is working on your Pi, build the Docker image using the included `Dockerfile`.

```sh
docker build -t rpi-envirophat .
```

### Run the Docker image

The Docker image assumes you want to mount your executable Python scripts at `/data` (which is defined as a `VOLUME` and the `WORKDIR`) so the `CMD` has been defined as `python3`. To run your scripts, add them to the container via volume, along with the `/dev` directory and add your main script as an argument to the `docker run` command. In this example, inside the working directory `./data` is a script named `read-weather-sensors.py`.

```python
from envirophat import weather, light
from subprocess import PIPE, Popen
import sys, time, csv

def get_cpu_temp():
	process = Popen(['vcgencmd', 'measure_temp'], stdout=PIPE)
	output, _error = process.communicate()
	return float(output[5:9])

def read_sensor():
	fields = ['timestamp', 'cpu_temp', 'weather_temp', 'weather_pressure', 'light_r', 'light_g', 'light_b', 'light_level']
	w = csv.DictWriter(sys.stdout, fieldnames=fields)

	lr, lg, lb = light.rgb()
	data = {
		'timestamp': time.time(),
		'cpu_temp': get_cpu_temp(),
		'weather_temp': weather.temperature(),
		'weather_pressure': weather.pressure(),
		'light_r': lr,
		'light_g': lg,
		'light_b': lb,
		'light_level': light.light()
	}
	w.writerow(data)

if __name__ == '__main__':
	read_sensor()
```

#### Read the sensor

You can run this script interactively from an SSH session.

```sh
docker run --privileged \
    -v $(realpath ./data):/data \
    rpi-envirophat \
    read-weather-sensors.py
```

#### Run from crontab

Or, you can run this script periodically by setting up a `crontab` entry for every minute that invokes the above `docker run` command and pipes the output to a file somewhere via `>>/data/sensor.log`.