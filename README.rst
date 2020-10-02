=======================================================
GAIA-X SCS Identity and Access Management (IAM) testbed
=======================================================

This testbed provides a minimized GAIA-X Sovereign Cloud Stack (SCS) environment.
By default MariaDB, Keystone, Keyloak and Horizon are deployed.

It focuses on working with Keystone and Keycloak in the context
of the GAIA-X MVP WP.

The testbed is based on the `testbed of the OSISM project <https://github.com/osism/testbed>`_.
Documentation is available at https://docs.osism.de/testbed/.

Usage
=====

* Create ``clouds.yaml`` and ``secure.yaml`` in the ``terraform`` directory
* Execute ``make ENVIRONMENT=betacloud deploy`` within the ``terraform`` directory
  (``betacloud`` is replaced with the CSP to be used)
* The progress of the deployment can be checked with ``make ENVIRONMENT=betacloud log``
* After completion of the deployment a login via ``make ENVIRONMENT=betacloud login``
  is possible
* For access to the web interfaces and API endpoints a tunnel can be created with
  ``make ENVIRONMENT=betacloud tunnel`` (https://github.com/sshuttle/sshuttle must
  be installed)
* Add ``192.168.16.9 testbed-gx-iam.osism.test`` to your local ``/etc/hosts`` file
* It is possible to customize ``testbed-gx-iam.osism.test``, for this purpose add
  ``PARAMS="-var endpoint=somehost.example.com"``
* It is possible to import an existing floating IP adress

  .. code-block:: console

     $ make ENVIRONMENT=betacloud attach PARAMS=4b041998-7c8d-4058-af01-f164e89c10bc
     openstack_networking_floatingip_v2.manager_floating_ip: Importing from ID "4b041998-7c8d-4058-af01-f164e89c10bc"...
     openstack_networking_floatingip_v2.manager_floating_ip: Import prepared!
       Prepared openstack_networking_floatingip_v2 for import
     openstack_networking_floatingip_v2.manager_floating_ip: Refreshing state... [id=4b041998-7c8d-4058-af01-f164e89c10bc]

     Import successful!

     The resources that were imported are shown above. These resources are now in
     your Terraform state and will henceforth be managed by Terraform.

  * After the import the address is managed by Terraform, if it should not be deleted by
    a ``make clean``, the address must be removed from the Terraform state first

    .. code-block:: console

       $ make ENVIRONMENT=betacloud detach
       Removed openstack_networking_floatingip_v2.manager_floating_ip
       Successfully removed 1 resource instance(s).

Webinterfaces & API endpoints
=============================

The web interfaces and API endpoints can also be accessed externally via
the assigned floating IP address of the instance (run
``make ENVIRONMENT=betacloud endpoints``).

================ =========================== ========= ================
Name             URL                         Username  Password
================ =========================== ========= ================
ARA              http://192.168.16.5:8120    ara       password
Cockpit          https://192.168.16.5:8130   dragon    da5pahthaew2Pai2
Horizon          http://192.168.32.9         admin     password
Keycloak         http://192.168.32.9:8170    admin     password
Keystone         http://192.168.32.9:35357   admin     password
Keystone         http://192.168.32.9:5000    admin     password
phpMyAdmin       http://192.168.16.5:8110    root      password
================ =========================== ========= ================
