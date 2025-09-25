@isTest
private class RentalAutomationSchedulerTest {
    
    @isTest
    static void testScheduleAllJobs() {
        Test.startTest();
        RentalAutomationScheduler.scheduleAllJobs();
        Test.stopTest();
        
        // Verify all jobs were scheduled
        List<CronTrigger> scheduledJobs = [
            SELECT Id, CronJobDetail.Name 
            FROM CronTrigger 
            WHERE CronJobDetail.Name IN (
                'Daily Rental Reminders',
                'Weekly Rental Reminders',
                'Monthly Rental Reminders',
                'Overdue Contract Monitor'
            )
        ];
        
        System.assertEquals(4, scheduledJobs.size());
    }
    
    @isTest
    static void testUnscheduleAllJobs() {
        // First schedule some jobs
        RentalAutomationScheduler.scheduleAllJobs();
        
        Test.startTest();
        RentalAutomationScheduler.unscheduleAllJobs();
        Test.stopTest();
        
        // Verify jobs were unscheduled
        List<CronTrigger> remainingJobs = [
            SELECT Id, CronJobDetail.Name, State
            FROM CronTrigger 
            WHERE CronJobDetail.Name IN (
                'Daily Rental Reminders',
                'Weekly Rental Reminders',
                'Monthly Rental Reminders',
                'Overdue Contract Monitor'
            )
        ];
        
        // Jobs should either be deleted or in DELETED state
        for (CronTrigger job : remainingJobs) {
            System.assertEquals('DELETED', job.State);
        }
    }
    
    @isTest
    static void testGetScheduledJobStatus() {
        // Schedule some jobs first
        RentalAutomationScheduler.scheduleAllJobs();
        
        Test.startTest();
        List<String> jobStatus = RentalAutomationScheduler.getScheduledJobStatus();
        Test.stopTest();
        
        // Verify status was retrieved
        System.assertEquals(4, jobStatus.size());
        
        for (String status : jobStatus) {
            System.assert(status.contains('SCHEDULED') || status.contains('NOT SCHEDULED'));
        }
    }
}