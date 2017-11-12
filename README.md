# RESTful-Samples
Samples for Building RESTful services using OpenEdge 11.7 Web Handlers

# Project Stucture

- DB: a standard Sports2000 database
- restfulpasoe: a PASOE instance
- Samples: a PDSOE project with sample code

# PASOE

The PASOE has been created with the following command

```
c:\progress\OpenEdge117_64\servers\pasoe\bin\tcman create -p 8830 -s 8831 -P 8832 -j 8833 restfulpasoe
```

When recreating is, we recommend to merge the conf\openedge.properties with your new instance.

The relevant configuration settings are:

- Startup parameters with connection to the sports2000 database
- PROPATH to include the Samples directory
- Web handler configuration for RESTful samples

# Sample URLs

- http://localhost:8830/web/Salesreps/BBB
