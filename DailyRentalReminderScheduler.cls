public class DailyRentalReminderScheduler implements Schedulable {
    
    public void execute(SchedulableContext ctx) {
        RentalReminderBatch dailyBatch = new RentalReminderBatch('Daily');
        Database.executeBatch(dailyBatch, 200);
    }
}