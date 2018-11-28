from pecan import rest, expose

from aibuild.common.log_utils import LOG
from aibuild.db import api


class ImageBuildController(rest.RestController):

    def __init__(self):
        super(ImageBuildController, self).__init__()
        self.dbapi = api.API()

    @expose('json')
    def hello(self):
        return {'msg': 'Hello!'}

    @expose('json')
    def post(self, **kwargs):
        LOG.info('New build log received %s', kwargs)

        try:
            image_uuid = self.dbapi.add_build_log(kwargs)
        except Exception as e:
            LOG.error('Got error %s', e)
            return dict(status=500, message=e.message)

        LOG.info('Add build log successfully!')
        kwargs['id'] = image_uuid
        return dict(status=200, **kwargs)
