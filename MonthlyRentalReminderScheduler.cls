public class MonthlyRentalReminderScheduler implements Schedulable {
    
    public void execute(SchedulableContext ctx) {
        RentalReminderBatch monthlyBatch = new RentalReminderBatch('Monthly');
        Database.executeBatch(monthlyBatch, 200);
    }
}