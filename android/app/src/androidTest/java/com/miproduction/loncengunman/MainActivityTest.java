package com.miproduction.loncengunman;

import androidx.test.platform.app.InstrumentationRegistry;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import org.junit.runners.Parameterized.Parameters;
import pl.leancode.patrol.PatrolJUnitRunner;

/**
 * Patrol instrumentation test — bridges JUnit ↔ Flutter Dart tests.
 *
 * Each `testCases()` entry becomes a parameterized JUnit test method that
 * delegates to PatrolJUnitRunner, which runs the corresponding Dart test
 * inside the running app process. This file is REQUIRED for `patrol test`
 * to discover any tests; without it Gradle's :app:connectedAndroidTest
 * reports "No tests found, nothing to do."
 *
 * Reference: https://patrol.leancode.co/documentation#android-setup
 * (verbatim from official patrol-4.9.0 example, with package adjusted to
 * this project's applicationId).
 */
@RunWith(Parameterized.class)
public class MainActivityTest {
    @Parameters(name = "{0}")
    public static Object[] testCases() {
        PatrolJUnitRunner instrumentation = (PatrolJUnitRunner) InstrumentationRegistry.getInstrumentation();
        instrumentation.setUp(MainActivity.class);
        instrumentation.waitForPatrolAppService();
        return instrumentation.listDartTests();
    }

    public MainActivityTest(String dartTestName) {
        this.dartTestName = dartTestName;
    }

    private final String dartTestName;

    @Test
    public void runDartTest() {
        PatrolJUnitRunner instrumentation = (PatrolJUnitRunner) InstrumentationRegistry.getInstrumentation();
        instrumentation.runDartTest(dartTestName);
    }
}