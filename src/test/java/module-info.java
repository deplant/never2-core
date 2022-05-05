module test {
    requires jdk.incubator.foreign;
    requires jdk.unsupported;
    requires java4ever.binding;
    requires java4ever.framework;
    requires org.junit.jupiter.api;
    requires org.apache.logging.log4j;
    requires com.google.gson;
    requires java.scripting;
    requires static lombok;
    opens contracts to com.google.gson;
    opens tst to com.google.gson;
    exports tst;
    exports contracts;
}