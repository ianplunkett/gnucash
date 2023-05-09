%typemap(in) time64 {
  if ($input->IsDate() || $input->IsInt32()) {
    if ($input->IsDate()) {
      v8::Local<v8::Date> date = v8::Local<v8::Date>::Cast($input);
      double timestamp = date->ValueOf();
      $1 = static_cast<time64>(timestamp / 1000);  // Convert milliseconds to seconds
    } else {
      $1 = static_cast<time64>($input->Int32Value(v8::Isolate::GetCurrent()->GetCurrentContext()).ToChecked());
    }
  } else {
    SwigV8ThrowException("Date, DateTime, or Integer expected");
    return;
  }
}

%typemap(in) time64 * (time64 secs) {
  if ($input->IsDate() || $input->IsInt32()) {
    if ($input->IsDate()) {
      v8::Local<v8::Date> date = v8::Local<v8::Date>::Cast($input);
      double timestamp = date->ValueOf();
      secs = static_cast<time64>(timestamp / 1000);  // Convert milliseconds to seconds
      $1 = &secs;
    } else {
      secs = static_cast<time64>($input->Int32Value(v8::Isolate::GetCurrent()->GetCurrentContext()).ToChecked());
      $1 = &secs;
    }
  } else {
    SwigV8ThrowException("Date, DateTime, or Integer expected");
    return;
  }
}
/* A typemap for converting time64 values returned from functions to
   python dates. Note that we can't use Python DateTime's fromtimestamp function because it relies upon libc's
   localtime. Note also that while we create times with timegm we retrieve it with localtime */
%typemap(out) time64 {
  if ($1 == INT64_MAX) {
    $result = v8::Null(v8::Isolate::GetCurrent());
  } else {
    struct tm t;
    gnc_localtime_r(&$1, &t);
    v8::Isolate* isolate = v8::Isolate::GetCurrent();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    v8::Local<v8::Function> dateConstructor = v8::Local<v8::Function>::Cast(
        context->Global()->Get(context, v8::String::NewFromUtf8(isolate, "Date")).ToLocalChecked());
    double timestamp = 1000.0 * mktime(&t); // Convert seconds to milliseconds
    v8::Local<v8::Value> args[] = { v8::Number::New(isolate, timestamp) };
    v8::Local<v8::Object> dateObject = dateConstructor->NewInstance(context, 1, args).ToLocalChecked();
    $result = dateObject;
  }
}
// functions using a pointer to time64 to return data
// these are named typemaps focussing for
//
// gboolean qof_query_date_predicate_get_date (const QofQueryPredData *pd, time64 *date)
// gboolean xaccAccountGetReconcileLastDate (const Account *acc, time64 *last_date)
// gboolean xaccAccountGetReconcilePostponeDate (const Account *acc, time64 *postpone_date)
//
// python functions return a list where the first item is the boolean return value and
// the second item is a datetime object. This could be reduced to only returning a date or
// null
//
// the modifiable argument is omitted in python function call

%typemap(in, numinputs=0) time64 *date (time64 secs) {
    $1 = &secs;
}

%typemap(argout) time64 *date (time64 secs) {
  struct tm t;

  // SWIG 4.02 (maybe others?) generates a redundant variable "time64 secs20"
  // This line avoids the unused-variable warning
  (void)secs;

  // directly access return value (result) of function
  // only return datetime if TRUE
  if (result->IsTrue()) {
    gnc_localtime_r($1, &t);
    v8::Isolate *isolate = v8::Isolate::GetCurrent();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    v8::Local<v8::Function> dateConstructor = v8::Local<v8::Function>::Cast(
        context->Global()->Get(context, v8::String::NewFromUtf8(isolate, "Date")).ToLocalChecked());
    double timestamp = 1000.0 * mktime(&t); // Convert seconds to milliseconds
    v8::Local<v8::Value> args[] = {v8::Number::New(isolate, timestamp)};
    v8::Local<v8::Object> dateObject = dateConstructor->NewInstance(context, 1, args).ToLocalChecked();

    $result = v8::Array::New(isolate, 2);
    $result->Set(context, 0, result).ToLocalChecked();
    $result->Set(context, 1, dateObject).ToLocalChecked();
  } else {
    $result = v8::Array::New(isolate, 1);
    $result->Set(context, 0, result).ToLocalChecked();
  }
}


%apply time64 *date { time64 *last_date };
%apply time64 *date { time64 *postpone_date };
