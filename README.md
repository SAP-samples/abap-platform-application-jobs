# SAP-samples/repository-template
This default template for SAP Samples repositories includes files for README, LICENSE, and .reuse/dep5. All repositories on github.com/SAP-samples will be created based on this template.

# Containing Files

1. The LICENSE file:
In most cases, the license for SAP sample projects is `Apache 2.0`.

2. The .reuse/dep5 file: 
The [Reuse Tool](https://reuse.software/) must be used for your samples project. You can find the .reuse/dep5 in the project initial. Please replace the parts inside the single angle quotation marks < > by the specific information for your repository.

3. The README.md file (this file):
Please edit this file as it is the primary description file for your project. You can find some placeholder titles for sections below.

# How to schedule application jobs from a RAP-based business object

<!--- Register repository https://api.reuse.software/register, then add REUSE badge:
[![REUSE status](https://api.reuse.software/badge/github.com/SAP-samples/REPO-NAME)](https://api.reuse.software/info/github.com/SAP-samples/REPO-NAME)
-->

## Description
<!-- Please include SEO-friendly description -->
In this repository you will find the implementation of a simple RAP (ABAP RESTful application programming model) business object that allows you to schedule a class as an application job that takes the semantic key of the selected entity as a parameter. This way it is possible to perform a long running calculation (the determination of inventory data) for a specific inventory id.

It will especially show how this class can also be run interactively thereby allowing the developer to debug the implementation, which is not possible when the code is executed in the background as an application job.

In addition, you will find working sample code that allows you to start an application job via an action of the RAP business object and what needs to be implemented to display the job status in a nice way in the SAP Fiori UI using virtual fields that always reflect the current status highlighting the criticality (aborted, running, finished, and others statuses) and the job status text in the Fiori list report. The package comes with a setup class that uses the released application APIs to create the application log object, the job catalog entry, and the job template.

## Requirements

## Download and Installation

## Known Issues
<!-- You may simply state "No known issues. -->

## How to obtain support
[Create an issue](https://github.com/SAP-samples/<repository-name>/issues) in this repository if you find a bug or have questions about the content.
 
For additional support, [ask a question in SAP Community](https://answers.sap.com/questions/ask.html).

## Contributing
If you wish to contribute code, offer fixes or improvements, please send a pull request. Due to legal reasons, contributors will be asked to accept a DCO when they create the first pull request to this project. This happens in an automated fashion during the submission process. SAP uses [the standard DCO text of the Linux Foundation](https://developercertificate.org/).

## License
Copyright (c) 2022 SAP SE or an SAP affiliate company. All rights reserved. This project is licensed under the Apache Software License, version 2.0 except as noted otherwise in the [LICENSE](LICENSE) file.
