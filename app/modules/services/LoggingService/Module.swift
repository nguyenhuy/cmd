Target.module(
  name: "LoggingService",
  dependencies: [
    .product(name: "Sentry", package: "sentry-cocoa"),
    "ConcurrencyFoundation",
    "FoundationInterfaces",
    "LoggingServiceInterface",
    "ThreadSafe",
  ],
  testDependencies: [])
