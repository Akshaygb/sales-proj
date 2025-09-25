@isTest
private class SchedulerTest {
    
    @isTest
    static void testDailyReminderScheduler() {
        Test.startTest();
        DailyRentalReminderScheduler scheduler = new DailyRentalReminderScheduler();
        String cronExp = '0 0 9 * * ?';
        System.schedule('Test Daily Scheduler', cronExp, scheduler);
        Test.stopTest();
        
        // Verify scheduler was created
        List<CronTrigger> scheduledJobs = [
            SELECT Id, CronJobDetail.Name 
            FROM CronTrigger 
            WHERE CronJobDetail.Name = 'Test Daily Scheduler'
        ];
        
        System.assertEquals(1, scheduledJobs.size());
    }
    
    @isTest
    static void testWeeklyReminderScheduler() {
        Test.startTest();
        WeeklyRentalReminderScheduler scheduler = new WeeklyRentalReminderScheduler();
        String cronExp = '0 0 10 * * ?';
        System.schedule('Test Weekly Scheduler', cronExp, scheduler);
        Test.stopTest();
        
        // Verify scheduler was created
        List<CronTrigger> scheduledJobs = [
            SELECT Id, CronJobDetail.Name 
            FROM CronTrigger 
            WHERE CronJobDetail.Name = 'Test Weekly Scheduler'
        ];
        
        System.assertEquals(1, scheduledJobs.size());
    }
    
    @isTest
    static void testMonthlyReminderScheduler() {
        Test.startTest();
        MonthlyRentalReminderScheduler scheduler = new MonthlyRentalReminderScheduler();
        String cronExp = '0 0 11 * * ?';
        System.schedule('Test Monthly Scheduler', cronExp, scheduler);
        Test.stopTest();
        
        // Verify scheduler was created
        List<CronTrigger> scheduledJobs = [
            SELECT Id, CronJobDetail.Name 
            FROM CronTrigger 
            WHERE CronJobDetail.Name = 'Test Monthly Scheduler'
        ];
        
        System.assertEquals(1, scheduledJobs.size());
    }
    
    @isTest
    static void testOverdueContractMonitor() {
        Test.startTest();
        OverdueContractMonitor scheduler = new OverdueContractMonitor();
        String cronExp = '0 0 8 * * ?';
        System.schedule('Test Overdue Monitor', cronExp, scheduler);
        Test.stopTest();
        
        // Verify scheduler was created
        List<CronTrigger> scheduledJobs = [
            SELECT Id, CronJobDetail.Name 
            FROM CronTrigger 
            WHERE CronJobDetail.Name = 'Test Overdue Monitor'
        ];
        
        System.assertEquals(1, scheduledJobs.size());
    }
}
