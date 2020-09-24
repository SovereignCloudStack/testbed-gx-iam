================================================
SCS Identity and Access Management (IAM) testbed
================================================

This testbed provides a minimized SCS manager node. By default MariaDB,
Keystone, Keyloak and Horizon are deployed.

This testbed focuses on working with Keystone and Keycloak in the context
of the GAIA-X MVP WP.

The testbed is based on the `testbed of the OSISM project <https://github.com/osism/testbed>`_.
Documentation is available at https://docs.osism.de/testbed/.

Usage
=====

* Create ``clouds.yaml`` and ``secure.yaml`` in the ``terraform`` directory
* Execute ``make deploy ENVIRONMENT=betacloud`` within the ``terraform`` directory
  (``betacloud`` is replaced with the CSP to be used)
* The progress of the deployment can be checked with ``make console ENVIRONMENT=betacloud``
* After completion of the deployment a login via ``make ssh ENVIRONMENT=betacloud``
  is possible
* For access to the web interfaces and API endpoints a tunnel can be created with
  ``make sshuttle ENVIRONMENT=betacloud`` (``sshuttle`` must be installed)

Webinterfaces & API endpoints
=============================

The web interfaces and API endpoints can also be accessed externally via
the assigned floating IP address of the instance (run
``make endpoints ENVIRONMENT=betacloud``).

================ =========================== ========= ================
Name             URL                         Username  Password
================ =========================== ========= ================
ARA              http://192.168.16.5:8120    ara       password
Cockpit          https://192.168.16.5:8130   dragon    da5pahthaew2Pai2
Horizon          http://192.168.16.9         admin     password
Keycloak         http://192.168.16.5:8170    admin     password
Keystone         http://192.168.16.9:35357   admin     password
Keystone         http://192.168.16.9:5000    admin     password
RabbitMQ         http://192.168.16.5:15672   openstack password
phpMyAdmin       http://192.168.16.5:8110    root      password
================ =========================== ========= ================
