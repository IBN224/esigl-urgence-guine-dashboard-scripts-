# Superset Deployment using Docker Compose
See https://superset.apache.org/docs/installation/docker-compose for the steps.

## in superset_config.py file add the following lines

1. To be able to use SQL Templating ENABLE_TEMPLATE_PROCESSING feature flag needs to be enabled in superset_config.py
 for more see https://superset.apache.org/docs/configuration/sql-templating/#jinja-templates

 add this line inside FEATURE_FLAGS
 ```
   "ENABLE_TEMPLATE_PROCESSING":True
 ```

 and it should look like this

  FEATURE_FLAGS = {
    "ALERT_REPORTS": True, 
    "ENABLE_TEMPLATE_PROCESSING":True
  }

 2. add these lines for the current year and month
  
 ```
    from datetime import datetime

    def current_year():
        return datetime.now().year

    def current_month():
        return datetime.now().month

    # Add custom Jinja context
    JINJA_CONTEXT_ADDONS = {
        "current_year": current_year,
        "current_month": current_month,
    }
    
 ```






