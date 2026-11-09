import pick from '../utils/pick';
import catchAsync from '../utils/catchAsync';
import { activityLogService } from '../services';

const getActivityLogs = catchAsync(async (req, res) => {
  const filter = pick(req.query, ['userId']);
  const options = pick(req.query, ['sortBy', 'limit', 'page']);
  const result = await activityLogService.queryActivityLogs(filter, options);
  res.send(result);
});

export default {
  getActivityLogs
};