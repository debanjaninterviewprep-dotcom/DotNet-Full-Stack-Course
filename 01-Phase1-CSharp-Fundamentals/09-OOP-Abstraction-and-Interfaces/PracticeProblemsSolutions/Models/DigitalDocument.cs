class DigitalDocument : IPrintable, IEmailable
{
    public void Print()
    {
        Console.WriteLine("Printing digital document...");
    }

    public void SendEmail()
    {
        Console.WriteLine("Sending digital document via email...");
    }
}