## InfluxDB 2.0 for [ATS]

[Apache traffic control][ATS] is a fast, scalable and extensible open-source CDN.
The default timeseries database in use is InfluxDB 1.8, which is quite dated and has been replaced by InfluxDB 2.0.
This repository contains a composition and the necessary scripts to run InfluxDB 2.0 with ATS via the v1 compatibility API.

### Usage
- Edit the `compose.yml` file and set the environment variables to your liking.
- Then run `docker compose up -d` to start InfluxDB.
- Edit your Traffic Ops instance's `influxdb.conf` to point to the new InfluxDB instance.
- Edit your Traffic Stats instance's `traffic_stats.cfg` to point to the new InfluxDB instance.
- Add a new server in Traffic Portal with the new InfluxDB instance's IP address and port.

Refer to the [ATS documentation] for more information on how to configure ATS.

[ATS]: https://github.com/apache/trafficcontrol
[ATS documentation]: https://traffic-control-cdn.readthedocs.io/en/latest/

## License
This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
