using System;

namespace PracticeProblemsSolutions
{
	class Program
	{
		static void Main(string[] args)
		{
			// ===============================
			// Problem 1: Secure User Profile
			// ===============================
			// UserProfile with read-only Id, public-read private-set Email/Username, fully private Password with validation methods.

			Console.WriteLine("Problem 1: Secure User Profile");

			UserProfile user = new UserProfile(1, "JohnDoe", "john.doe@example.com", "Password123");
			Console.WriteLine($"Username: {user.UserName}");
			Console.WriteLine($"Email: {user.Email}");
			Console.WriteLine($"Created At: {user.CreatedAt}");

			user.ChangeUserName("JaneDoe");
			user.ChangeEmail("jane.doe@example.com");

			Console.WriteLine($"Updated Username: {user.UserName}");
			Console.WriteLine($"Updated Email: {user.Email}");


			// ===============================
			// Problem 2: Temperature Sensor
			// ===============================
			// Encapsulated readings list, Location property, count/average/min/max computed properties, static sensor count.

			Console.WriteLine("\nProblem 2: Temperature Sensor");
			
			TemperatureSensor sensor1 = new TemperatureSensor("Living Room");
			sensor1.AddReading(22.5);
			sensor1.AddReading(23.0);
			sensor1.AddReading(21.8);

			Console.WriteLine($"Sensor Location: {sensor1.Location}");
			Console.WriteLine($"Average Temperature: {sensor1.GetAverageTemperature}");
			Console.WriteLine($"Max Temperature: {sensor1.GetMaxTemperature}");
			Console.WriteLine($"Min Temperature: {sensor1.GetMinTemperature}");
			Console.WriteLine($"Total Sensors: {TemperatureSensor.SensorCount}");

			sensor1.ClearReadings();
			Console.WriteLine($"Readings after clearing: {sensor1.GetReadings().Count}");


			// ===============================
			// Problem 3: Banking System
			// ===============================
			// BankAccount with private balance, static Bank class managing accounts, transfer method with transaction history.

			Console.WriteLine("\nProblem 3: Banking System");

			Bank.CreateAccount(1001, "Alice", 5000m, 1234);
			Bank.CreateAccount(1002, "Bob", 3000m, 5678);

			BankAccount aliceAccount = Bank.GetAccount(1001);
			BankAccount bobAccount = Bank.GetAccount(1002);

			aliceAccount.Deposit(2000m);
			aliceAccount.Withdraw(1500m, 1234);
			bobAccount.Deposit(1000m);
			bobAccount.Withdraw(500m, 5678);
			aliceAccount.Transfer(bobAccount, 1000m, 1234);
			aliceAccount.GetStatement(1234);
			bobAccount.GetStatement(5678);

			Console.WriteLine($"Total Balance in Bank: ${Bank.GetTotalBalance()}");

			// ===============================
			// Problem 4: Encapsulated Game Character
			// ===============================
			// Base Character with private stats, protected inventory for derived classes, methods for attack/heal/levelup.

			Console.WriteLine("\nProblem 4: Encapsulated Game Character");

			Warrior thor = new Warrior("Thor");
			Mage merlin = new Mage("Merlin");

			thor.Shield();
			merlin.CastSpell();

			thor.Attack(merlin);
			merlin.TakeDamage(15);
			merlin.Heal(10);
			thor.LevelUp();
			thor.GainXP(20);
			merlin.LevelUp();

			thor.DisplayStats();
			merlin.DisplayStats();

			// ===============================
			// Problem 5: TaskFlow Complete OOP System
			// ===============================
			// Comprehensive system combining encapsulation, inheritance, abstraction, and polymorphism with all OOP concepts.

			Console.WriteLine("\nProblem 5: TaskFlow Complete OOP System");

			Sprint sprint1 = new Sprint("Sprint 1", DateTime.Now, DateTime.Now.AddDays(14), 5);

			Feature feature1 = new Feature(1, "Implement Login", "5", "User can log in with valid credentials.");
			BugReport bug1 = new BugReport(2, "Fix Login Bug", "High", "Steps to reproduce the login bug.");

			Feature feature2 = new Feature(3, "Implement Registration", "8", "User can register with valid details.");
			BugReport bug2 = new BugReport(4, "Fix Registration Bug", "Medium", "Steps to reproduce the registration bug.");

			sprint1.AddWorkItem(feature1);
			sprint1.AddWorkItem(bug1);
			sprint1.AddWorkItem(feature2);
			sprint1.AddWorkItem(bug2);

			sprint1.GetBoard();
			
			TeamMember alice = new TeamMember("Alice", "Developer");
			TeamMember bob = new TeamMember("Bob", "Tester");

			alice.AssignWorkItem(feature1);
			alice.AssignWorkItem(feature2);
			bob.AssignWorkItem(bug1);
			bob.AssignWorkItem(bug2);

			alice.GetWorkload();
			bob.GetWorkload();

		}
	}
}
