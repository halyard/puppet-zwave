# @summary Configure ZWave-js-ui
#
# @param datadir sets where the data is persisted
# @param dongle sets the device path for the USB dongle
# @param hostname is the hostname for log submission
# @param aws_access_key_id sets the AWS key to use for Route53 challenge
# @param aws_secret_access_key sets the AWS secret key to use for the Route53 challenge
# @param email sets the contact address for the certificate
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
  String $aws_access_key_id,
  String $aws_secret_access_key,
  String $email,
  String $container_ip = '172.17.0.2',
  Integer $port = 8443,
  Optional[String] $backup_target = undef,
  Optional[String] $backup_watchdog = undef,
  Optional[String] $backup_password = undef,
  Optional[Hash[String, String]] $backup_environment = undef,
  Optional[String] $backup_rclone = undef,
) {
  file { [$datadir, "${datadir}/store"]:
    ensure => directory,
  }

  -> docker::container { 'zwave':
    image => 'ghcr.io/zwave-js/zwave-js-ui:latest',
    args  => [
      "--device=${dongle}:/dev/zwave",
      "-v ${datadir}/store:/usr/src/app/store",
    ],
    cmd   => '',
  }

  nginx::site { $hostname:
    proxy_target          => "http://${container_ip}:8091",
    aws_access_key_id     => $aws_access_key_id,
    aws_secret_access_key => $aws_secret_access_key,
    email                 => $email,
    csp                   => "default-src 'self' http: https: ws: wss: data: blob: 'unsafe-inline' 'unsafe-eval'; frame-ancestors 'self';",
    port                  => $port,
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
