# Workaround for missing Flows interface on QRadar 7.x

After updating my QRadar lab to version 7.5, it seems I hit a wall in getting Network Interface Flows to work.
The GUI was not picking up the network interfaces list:

![screenshot](https://github.com/davidedg/QRadar-notes/raw/main/LAB_qflow_interface_no_nic/qradar_75_qflow_interface_missing_nic.PNG)

**(note the *"No unconfigured flow interface detected for selected Flow Collector"*).**

At first I tried to add another interface and explicitly configure it as a monitor one, but that didn't help.
I also tried searching online, both on release notes and online forums, but have not come up with anything related to this issue. Maybe I am just missing something.

As this is just for my home lab, I decided to dig deeper and see if I could somehow "inject" the configuration manually, mainly to hack a little bit more into the product.

After using vast amounts of grepping, sql full query logging and vm snapshots...  these are my findings.
**Needless to say, DON'T YOU EVER DARE TO USE IT IN PRODUCTION !!**



Basically, when a flow source is defined, some new rows are added into console postgres db.

The order of the tasks is:
1. Ensure there are no pending deployments
2. Create a Flow Source Config (table flowsource_config and sequence flowsourceconfig_sequence )
3. Define config parameters, like the interface to be used and a capture filter (table `flowsource_config_parameters` and sequence `flowsource_config_parameters_sequence`)
4. Create the new FlowSource, referring the Flow Source Config (table `flowsource` and sequence `flowsource_sequence`)
5. Notify the update (tables `deployed_component`  and `ServerHost`)
6. Deploy configuration (this should also populate table `flowsource_lookup`)

See [qradar_75_qflow_missing_nic.sql](https://github.com/davidedg/QRadar-notes/blob/main/LAB_qflow_interface_no_nic/qradar_75_qflow_missing_nic.sql) for the details.
