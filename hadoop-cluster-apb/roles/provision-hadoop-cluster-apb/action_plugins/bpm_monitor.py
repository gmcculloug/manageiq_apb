from ansible.plugins.action import ActionBase
import yaml
import time

class ActionModule(ActionBase):
    def run(self, tmp=None, task_vars=None):

        if task_vars is None:
            task_vars = dict()

        result = super(ActionModule, self).run(tmp, task_vars)

        delay = int(self._task.args.get('delay', 10))
        retries = int(self._task.args.get('retries', 5))
        config_map_args = dict(namespace=self._task.args.get('namespace'), name=self._task.args.get('name'))
        uri_module_args = self._task.args.get('uri')

        for i in range(1, retries):
            result['uri_result'] = self._execute_module(module_name='uri',
                    module_args=uri_module_args,
                    task_vars=task_vars, tmp=tmp)
            status_data = result['uri_result']['json']['process-instance-variables']
            config_map_args['data'] = {'status': yaml.safe_dump(status_data, default_flow_style=False)}
            result['config_result'] = self._execute_module(module_name='k8s_v1_config_map',
                    module_args=config_map_args,
                    task_vars=task_vars, tmp=tmp)

            result['changed'] = True

            process_dict = result['uri_result']['json']['process-instance-state']
            if process_dict == 2:
                if 'approval_status' in status_data and status_data['approval_status'] == 'Approved':
                    result['failed'] = False
                    return result
                elif 'approval_status' in status_data and status_data['approval_status'] == 'Denied':
                    self.create_error_message("Request has been denied")
                    result['failed'] = True
                    return result


            time.sleep(delay)

        result['failed'] = True
        return result

    def create_error_message(self, error_string):
        file = open("/dev/termination-log","w")
        file.write(error_string)
        file.close()
