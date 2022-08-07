# @summary Configure ZWavejs2Mqtt
#
# @param datadir sets where the data is persisted
# @param dongle sets the device path for the USB dongle
# @param hostname is the hostname for log submission
# @param tls_account is the account details for requesting the TLS cert
# @param tls_challengealias is the domain to use for TLS cert validation
# @param container_ip sets the IP address for the docker container
class zwave (
  String $datadir,
  String $dongle,
  String $container_ip = '172.17.0.2',
) {
  file { "${datadir}/store":
    ensure => directory,
  }

  -> docker::container { 'zwave':
    image => 'zwavejs/zwavejs2mqtt:latest',
    args  => [
      "--device=${dongle}:/dev/zwave",
      "-v ${datadir}/store:/usr/src/app/store",
    ],
    cmd   => '',
  }

  nginx::site { $hostname:
    proxy_target       => "http://${container_ip}:8091",
    tls_challengealias => $tls_challengealias,
    tls_account        => $tls_account,
  }
}
