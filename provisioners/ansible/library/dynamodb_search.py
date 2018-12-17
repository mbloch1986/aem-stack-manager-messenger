#!/usr/bin/python

ANSIBLE_METADATA = {'metadata_version': '1.1'}

DOCUMENTATION = """
module: dynamodb_search
short_description: Scan and query DB Table
version_added: "1.0"
description:
  - Scan DynamoDB Table for given Attribute value.
  - Query DynamoDB with KeyConditions.
requirements:
  - boto3 >= 1.0.0
options:
  state:
    description:
      - Scan or query Database table.
    required: true
    choices: ['scan', 'query']
    default: null
  table_name:
    description:
      - Name of the table.
    required: true
    default: null
  get_attribute:
    description:
      - Name of the Attribute to get from the table.
    required: true
    default: null
  select:
    description:
      - The attributes to be returned in the result.
    required: false
    choices: ['ALL_ATTRIBUTES', 'ALL_PROJECTED_ATTRIBUTES', 'SPECIFIC_ATTRIBUTES', 'COUNT']
    default: 'ALL_ATTRIBUTES'
  attribute:
    description:
      - Name of the Attribute to query/scan the table.
    required: true
    default: null
  attribute_value:
    description:
      - Value of the attribute in the table.
    required: true
    default: null
  comparisonoperator:
    description:
      - Comparison operator for matching the attribute_value with the attribute.
    required: false
    choices: ['EQ', 'NE', 'IN', 'LE', 'LT', 'GE', 'GT', 'BETWEEN', 'NOT_NULL', 'NULL', 'CONTAINS', 'NOT_CONTAINS', 'BEGINS_WITH']
    default: EQ
extends_documentation_fragment:
    - aws
    - ec2
"""

EXAMPLES = """
# Scan dynamo table for attribute message_id and only return attribute command_id
- dynamodb_search:
    table_name: "michaelb-aem63-AemStackManagerTable"
    attribute: "message_id"
    attribute_value: "123"
    comparisonoperator: "EQ"
    get_attribute: "command_id"
    select: "SPECIFIC_ATTRIBUTES"
    state: scan

# Scan dynamodb table for attribute message_id and return all attributes
- dynamodb_search:
    table_name: "michaelb-aem63-AemStackManagerTable"
    attribute: "message_id"
    attribute_value: "123"
    comparisonoperator: "EQ"
    select: "ALL_ATTRIBUTES"
    state: scan

# Query dynamo table for KeyConditions command_id and only return attribute state
- dynamodb_search:
    table_name: "michaelb-aem63-AemStackManagerTable"
    attribute: "command_id"
    attribute_value: "456"
    comparisonoperator: "EQ"
    get_attribute: "state"
    select: "SPECIFIC_ATTRIBUTES"
    state: query
"""

RETURN = """
msg:
    get_attribute: Value.
"""

import traceback

try:
    import botocore
    from ansible.module_utils.ec2 import ansible_dict_to_boto3_tag_list, boto3_conn
    HAS_BOTO = True
except ImportError:
    HAS_BOTO = False

from ansible.module_utils.basic import AnsibleModule
from ansible.module_utils.ec2 import AnsibleAWSError, connect_to_aws, ec2_argument_spec, get_aws_connection_info

def filter(module):
    table_name = module.params.get('table_name')
    state = module.params.get('state')
    get_attribute = module.params.get('get_attribute')
    limit = module.params.get('limit')
    select = module.params.get('select')
    attribute = module.params.get('attribute')
    attribute_value = module.params.get('attribute_value')
    comparisonoperator = module.params.get('comparisonoperator')

    if state == 'scan':
        if select == 'ALL_ATTRIBUTES':
            filter = {
                        'TableName': table_name,
                        'Limit': limit,
                        'Select': select,
                        'ScanFilter':{
                            attribute: {
                                'AttributeValueList': [
                                {'S': attribute_value,}
                                ],
                                'ComparisonOperator': comparisonoperator
                            }
                        }
                    }
        else:
            filter = {
                        'TableName': table_name,
                        'AttributesToGet': [
                            get_attribute,
                        ],
                        'Limit': limit,
                        'Select': select,
                        'ScanFilter':{
                            attribute: {
                                'AttributeValueList': [
                                {'S': attribute_value,}
                                ],
                                'ComparisonOperator': comparisonoperator
                            }
                        }
                    }
    elif state == 'query':
            filter = {
                        'TableName': table_name,
                        'AttributesToGet': [
                            get_attribute,
                        ],
                        'Limit': limit,
                        'Select': select,
                        'KeyConditions': {
                            attribute: {
                                'AttributeValueList': [
                                {'S': attribute_value,}
                                ],
                            'ComparisonOperator': comparisonoperator
                            }
                        }
                    }

    return filter

def dynamo_table_exists(module, resource_client):
    table_name = module.params.get('table_name')
    table = resource_client.Table(table_name)
    try:
        table.load()
        return True
    except:
        return False

def scan(client_connection, resource_connection, module):
    try:
        if dynamo_table_exists(module, resource_connection):
            scan_filter_dict = filter(module)
            response = client_connection.scan(**scan_filter_dict)

            while 'LastEvaluatedKey' in response:
                scan_filter_dict.update({'ExclusiveStartKey': response['LastEvaluatedKey']})
                response = client_connection.scan(**scan_filter_dict)

            result = response['Items']

        else:
            module.fail_json(msg="Error: Table not found")

    except Exception as e:
        module.fail_json(msg="Error: " + str(e), exception=traceback.format_exc(e))
    else:
        return result

def query(client_connection, resource_connection, module):
    try:
        if dynamo_table_exists(module, resource_connection):
            query_filter_dict = filter(module)
            response = client_connection.query(**query_filter_dict)

            while 'LastEvaluatedKey' in response:
                query_filter_dict.update({'ExclusiveStartKey': response['LastEvaluatedKey']})
                response = client_connection.scan(**query_filter_dict)

            result = response['Items']
        else:
            module.fail_json(msg="Error: Table not found")

    except Exception as e:
        module.fail_json(msg="Error: Can't execute query - " + str(e), exception=traceback.format_exc(e))
    else:
        return result

def main():
    argument_spec = ec2_argument_spec()
    argument_spec.update(dict(
        table_name = dict(required=True, type='str'),
        get_attribute = dict(type='str'),
        limit = dict(default=10000, type='int'),
        select = dict(default='ALL_ATTRIBUTES', type='str', choices=['ALL_ATTRIBUTES', 'ALL_PROJECTED_ATTRIBUTES', 'SPECIFIC_ATTRIBUTES', 'COUNT']),
        attribute = dict(type='str'),
        attribute_value = dict(default=[], type='str'),
        comparisonoperator = dict(default='EQ', type='str', choices=['EQ', 'NE', 'IN', 'LE', 'LT', 'GE', 'GT', 'BETWEEN', 'NOT_NULL', 'NULL', 'CONTAINS', 'NOT_CONTAINS', 'BEGINS_WITH']),
        state = dict(required=True, type='str', choices=['scan', 'query'])
    ))

    module = AnsibleModule(argument_spec=argument_spec)

    if not HAS_BOTO:
        module.fail_json(msg='boto3 required for this module')

    region, ec2_url, aws_connect_params = get_aws_connection_info(module, boto3=True)

    if not region:
        module.fail_json(msg='region must be specified')

    try:
        client_connection = boto3_conn(module, conn_type='client',
                resource='dynamodb', region=region,
                endpoint=ec2_url, **aws_connect_params)
        resource_connection = boto3_conn(module, conn_type='resource',
                resource='dynamodb', region=region,
                endpoint=ec2_url, **aws_connect_params)
    except botocore.exceptions.NoCredentialsError as e:
        module.fail_json(msg='cannot connect to AWS', exception=traceback.format_exc(e))

    state = module.params.get("state")

    if state == 'scan':
        result = scan(client_connection, resource_connection, module)
    elif state == 'query':
        result = query(client_connection, resource_connection, module)
    else:
        module.fail_json(msg='Error: unsupported state. Supported states are scan and query')

    module.exit_json(item=result)

if __name__ == '__main__':
    main()
