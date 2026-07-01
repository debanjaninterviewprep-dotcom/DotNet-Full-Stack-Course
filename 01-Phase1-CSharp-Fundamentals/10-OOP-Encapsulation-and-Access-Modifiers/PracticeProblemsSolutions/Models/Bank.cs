static class Bank
{
    private static List<BankAccount> _accounts = new List<BankAccount>();
    public static void CreateAccount(int accountNumber, string accountHolderName, decimal initialBalance, int pin)
    {
        BankAccount newAccount = new BankAccount(accountNumber, accountHolderName, initialBalance, pin);
        _accounts.Add(newAccount);
    }

    public static BankAccount GetAccount(int accountNumber)
    {
        return _accounts.FirstOrDefault(acc => acc.AccountNumber == accountNumber);
    }

    public static decimal GetTotalBalance()
    {
        return _accounts.Sum(acc => acc.Balance);
    }
}