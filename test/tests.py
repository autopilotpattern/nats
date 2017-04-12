"""
Integration tests for autopilotpattern/nats. These tests are executed
inside a test-running container based on autopilotpattern/testing.
"""
import os
from os.path import expanduser
import random
import subprocess
import string
import sys
import time
import unittest
import uuid

from testcases import AutopilotPatternTest, WaitTimeoutError, \
     dump_environment_to_file
import consul as pyconsul


class NatsTest(AutopilotPatternTest):

    project_name = 'nats'

    def setUp(self):
        """
        autopilotpattern/nats setup.sh writes an _env file with a CNS
        entry for Consul. If this has been mounted from the test environment,
        we'll use that, otherwise we have to generate it from the environment.
        Then make sure we use the external CNS name for the test rig.
        """
        account = os.environ['TRITON_ACCOUNT']
        dc = os.environ['TRITON_DC']
        internal = 'consul-nats.svc.{}.{}.cns.joyent.com'.format(account, dc)
        external = 'consul-nats.svc.{}.{}.triton.zone'.format(account, dc)
        test_consul_host = os.environ.get('CONSUL', external)

        if not os.path.isfile('_env'):
            os.environ['CONSUL'] = internal
            dump_environment_to_file('_env')

        os.environ['CONSUL'] = test_consul_host


    def test_join_cluster(self):
        """
        Check that 3 NATS servers can cluster together given a healthy one
        """
        self.instrument(self.wait_for_containers,
                        {'nats': 1, 'consul': 1}, timeout=300)
        self.compose_scale('nats', 2)
        self.instrument(self.wait_for_service, 'nats', count=2, timeout=120)

        _, nats1_ip = self.get_ips('nats_1')

        self.check_routes([nats1_ip], 'nats_2')


    def wait_for_containers(self, expected={}, timeout=30):
         """
         Waits for all containers to be marked as 'Up' for all services.
         `expected` should be a dict of {"service_name": count}.
         TODO: lower this into the base class implementation.
         """
         svc_regex = re.compile(r'^{}_(\w+)_\d+$'.format(self.project_name))

         def get_service_name(container_name):
             return svc_regex.match(container_name).group(1)

         while timeout > 0:
             containers = self.compose_ps()
             found = defaultdict(int)
             states = []
             for container in containers:
                 service = get_service_name(container.name)
                 found[service] = found[service] + 1
                 states.append(container.state == 'Up')
             if all(states):
                 if not expected or found == expected:
                     break
             time.sleep(1)
             timeout -= 1
         else:
             raise WaitTimeoutError("Timed out waiting for containers to start.")


    def check_routes(self, expected, container='nats_2', timeout=60):
        expected.sort()
        patt = '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\:6222'
        while timeout > 0:
            conf = self.docker_exec(container,
                                     'cat /etc/gnatsd.conf')
            actual = re.findall(patt, conf)
            actual = [IP(a.replace(':6222', '').strip())
                     for a in actual]
            actual.sort()
            if actual == expected:
               break

            timeout -= 1
            time.sleep(1)
        else:
            self.fail("expected {} but got {} for NATS routes"
                       .format(expected, actual))


if __name__ == "__main__":
    unittest.main()
