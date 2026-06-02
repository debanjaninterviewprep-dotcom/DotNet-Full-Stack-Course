
class Student
{
    private static int id_counter = 0;

    public int Id { get; private set; }
    public string Name { get; set; }
    public int[] Scores { get; private set; }

    private int scoreCount = 0; // tracks number of added scores

    public Student(string name)
    {
        Id = ++id_counter;
        Name = name;
        Scores = new int[5];
    }

    public void AddScore(int score)
    {
        if (scoreCount < 5)
        {
            Scores[scoreCount] = score;
            scoreCount++;
        }
        else
        {
            Console.WriteLine("Maximum scores reached.");
        }
    }

    public double GetAverageScore()
    {
        if (scoreCount == 0) return 0;
        int total = 0;
        for (int i = 0; i < scoreCount; i++)
        {
            total += Scores[i];
        }
        return (double)total / scoreCount;
    }

    public char GetGrade()
    {
        double average = GetAverageScore();
        if (average >= 90) return 'A';
        else if (average >= 80) return 'B';
        else if (average >= 70) return 'C';
        else if (average >= 60) return 'D'; 
        else return 'F';
    }

    public (int highest, int lowest) GetHighestAndLowest()
    {
        if (scoreCount == 0) return (0, 0);
        int highest = Scores[0];
        int lowest = Scores[0];
        for (int i = 1; i < scoreCount; i++)
        {
            if (Scores[i] > highest)
            {
                highest = Scores[i];
            }
            else if (Scores[i] < lowest)
            {
                lowest = Scores[i];
            }
        }
        return (highest, lowest);
    }

    public void DisplayInfo()
    {
        Console.WriteLine($"Student ID: {Id}");
        Console.WriteLine($"Name: {Name}");
        Console.WriteLine($"Scores: {string.Join(", ", Scores.Take(scoreCount))}");
        Console.WriteLine($"Average Score: {GetAverageScore():F2}");
        Console.WriteLine($"Grade: {GetGrade()}");
        var (highest, lowest) = GetHighestAndLowest();
        Console.WriteLine($"Highest Score: {highest}");
        Console.WriteLine($"Lowest Score: {lowest}");
    }
}
