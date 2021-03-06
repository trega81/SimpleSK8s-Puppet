# This module will COMPLETELY nuke and pave an existing kubernetes cluster.
# Make sure you know what you're doing if you run this.
# This is entirely destructive and will destroy any and all work you have.
# Once this has been completed, make sure you reboot all of the hosts.
plan deploy_k8s::nuke (
    Boolean           $confirm,
    Optional[Boolean] $remove_packages,
) {
# Only if confirm=true should this nuke the cluster and all nodes.
    if $confirm {
        apply(['k8s-primary','k8s-nodes'], _run_as => root) {
            # Stop the ETCD service
            service {'etcd':
                ensure => stopped,
            }

            # Nuke Everything
            exec {'nuke it all':
                command => '/usr/bin/kubeadm reset -f'
            }

            # Remove the /var/lib/etcd/member directory. Get rid of all 
            file {'/var/lib/etcd/member':
                ensure  => absent,
                purge   => true,
                force   => true,
                recurse => true,
                require => Service['etcd'],
            }

            # If remove_packages is True, remove all the Kube/Docker packages.
            if $remove_packages {
                # Define the K8s Packages to remove.
                $kube_packages = [ 'kubelet', 'kubectl', 'kubeadm', 'etcd', 'docker']

                package {$kube_packages:
                    ensure => purged,
                }
            }
        }
    }
}
