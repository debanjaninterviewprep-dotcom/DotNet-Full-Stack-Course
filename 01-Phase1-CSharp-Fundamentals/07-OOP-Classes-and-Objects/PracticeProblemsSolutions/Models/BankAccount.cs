public class BankAccount
{
    public readonly string accountNumber;
    public string AccountHolder { get; set; }
    public decimal Balance { get; private set; }

    public BankAccount(string accountNumber, string accountHolder, decimal initialBalance = 0)
    {
        this.accountNumber = accountNumber;
        AccountHolder = accountHolder;
        Balance = initialBalance;
    }

    public void Deposit(decimal amount)
    {
        if (amount > 0)
        {
            Balance += amount;
            Console.WriteLine($"Deposited {amount:C}. New Balance: {Balance:C}");
        }
        else
        {
            Console.WriteLine("Deposit amount must be positive.");
        }
    }

    public void Withdraw(decimal amount)
    {
        if (amount > Balance)
            Console.WriteLine("Insufficient balance.");
        else if (amount <= 0)
            Console.WriteLine("Withdrawal amount must be positive.");
        else
        {
            Balance -= amount;
            Console.WriteLine($"Withdrew {amount:C}. New Balance: {Balance:C}");
        }
    }

    public decimal DisplayBalance()
    {
        Console.WriteLine($"Current Balance: {Balance:C}");
        return Balance;
    }
}