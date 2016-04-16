###让程序从容的崩溃

1. 首先需要在appDelegate中使用InstallUncaughtExceptionHandler()用于监听
2. 添加UncaughtExceptionHandler这个类

iOS SDK提供的函数是NSSetUncaughtExceptionHandler来进行异常处理。但是无法处理内存访问错误、重复释放等错误,因为这些错误发送的SIGNAL。所以需要处理这些SIGNAL

来源：
> http://cocoawithlove.com/2010/05/handling-unhandled-exceptions-and.html
