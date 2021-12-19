const createError = require('http-errors');

// catch 404 and forward to error handler
exports.error_404 = function (req, res, next) {
    next(createError(404));
};
  
  // error handler
exports.error_500 = function (err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = process.env.NODE_ENV === 'development' ? err : {};
  
  console.log(err);
  
  // render the error page
  res.status(err.status || 500);
  res.send('error');
};