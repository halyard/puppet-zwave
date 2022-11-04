# @summary Configure ZWavejs2Mqtt
#
# @param datadir sets where the data is persisted
# @param dongle sets the device path for the USB dongle
# @param hostname is the hostname for log submission
# @param tls_account is the account details for requesting the TLS cert
# @param tls_challengealias is the domain to use for TLS cert validation
# @param container_ip sets the IP address for the docker container
# @param port sets the port to listen on
# @param backup_target sets the target repo for backups
# @param backup_watchdog sets the watchdog URL to confirm backups are working
# @param backup_password sets the encryption key for backup snapshots
# @param backup_environment sets the env vars to use for backups
# @param backup_rclone sets the config for an rclone backend
class zwave (
  String $datadir,
  String $dongle,
  String $hostname,
  String $tls_account,
  Optional[String] $tls_challengealias = undef,
  String $container_ip = '172.17.0.2',
  Integer $port = 8443,
  Optional[String] $backup_target = undef,
  Optional[String] $backup_watchdog = undef,
  Optional[String] $backup_password = undef,
  Optional[Hash[String, String]] $backup_environment = undef,
  Optional[String] $backup_rclone = undef,
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
    csp                => "default-src 'self' http: https: ws: wss: data: blob: 'unsafe-inline' 'unsafe-eval'; frame-ancestors 'self';",
    port               => $port,
  }

  if $backup_target != '' {
    backup::repo { 'zwave':
      source        => $datadir,
      target        => $backup_target,
      watchdog_url  => $backup_watchdog,
      password      => $backup_password,
      environment   => $backup_environment,
      rclone_config => $backup_rclone,
    }
  }
}
