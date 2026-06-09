using FluentAssertions;
using FluentValidation;
using Xunit;

namespace TaskFlow.Topic10.Unit;

// P1: validator + theories. Mirror your real CreateProjectValidator from Phase 5/6 here.
public sealed record CreateProjectCommand(string Name, string? Description);

public sealed class CreateProjectValidator : AbstractValidator<CreateProjectCommand>
{
    public CreateProjectValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(200);
        RuleFor(x => x.Description).MaximumLength(2000);
    }
}

public sealed class CreateProjectValidatorTests
{
    private readonly CreateProjectValidator _sut = new();

    [Fact]
    public void Name_required()
    {
        var result = _sut.Validate(new CreateProjectCommand("", null));
        result.IsValid.Should().BeFalse();
        result.Errors.Should().ContainSingle(e => e.PropertyName == nameof(CreateProjectCommand.Name));
    }

    [Theory]
    [InlineData(199, true)]
    [InlineData(200, true)]
    [InlineData(201, false)]
    public void Name_length_boundary(int length, bool expectedValid)
    {
        var name = new string('a', length);
        var result = _sut.Validate(new CreateProjectCommand(name, null));
        result.IsValid.Should().Be(expectedValid);
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData(null)]
    public void Name_blank_invalid(string? name)
    {
        _sut.Validate(new CreateProjectCommand(name!, null)).IsValid.Should().BeFalse();
    }
}
