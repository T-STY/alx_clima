# ALX-Clima Project Rules

## Read This First
Read this file at the start of every session before making any changes.

## Architecture & Scalability
- Design for large-scale traffic from day one: use lazy loading, pagination, caching, and efficient state management
- Use Provider with ChangeNotifier for state; migrate to Riverpod if complexity grows
- Keep all API calls behind a service layer with retry logic, rate limiting, and proper error handling
- Never hardcode API keys or secrets; use environment variables via --dart-define or .env files
- Implement proper input validation and sanitization at all system boundaries
- Use const constructors wherever possible for widget performance

## Code Style & Structure
- Modular architecture: no single-file coding; every screen, widget, provider, model, and service goes in its own file
- Zero comments in code: no //, no ///, no /* */; code must be self-documenting through clear naming
- Every opening bracket, parenthesis, or brace must have a matching close
- Use Dart trailing commas for all multi-line parameter lists
- Follow consistent naming: snake_case for files, PascalCase for classes, camelCase for variables and methods
- Use `withValues(alpha: x)` instead of `withOpacity(x)` for Color opacity (withOpacity is deprecated)

## Design Language
- Modern futuristic aesthetic inspired by Tesla and similar brands
- Font: Exo 2 via Google Fonts throughout the entire app
- Floating cards with subtle shadows or no shadows depending on context
- Elevation and depth through layered surfaces, not heavy borders
- Color palette: primary #0A84FF (blue), secondary #00D4FF (cyan), white backgrounds, light gray surfaces
- Rounded corners (12-16px radius) on cards, buttons, and containers
- Smooth entry animations using flutter_animate
- Icons: Iconsax icon set exclusively
- All user-facing text in Spanish

## Security
- Validate and sanitize all user inputs before processing
- Use HTTPS for all network requests
- Never log sensitive data (tokens, passwords, personal info)
- Implement proper error boundaries; never expose stack traces to users
- Guard against improper API usage with rate limiting and request validation in the service layer

## Pre-Commit Checklist
Before every commit and push:
1. Verify all brackets, parentheses, and braces are properly closed
2. Confirm zero comments exist in any dart file
3. Run a mental diff review of all changed files
4. Ensure no hardcoded secrets or API keys
5. Verify modular structure: no file exceeds 300 lines; split if needed
6. Confirm consistent design language (Exo 2 font, AppTheme colors, Iconsax icons)
7. Check that withValues(alpha:) is used instead of withOpacity()
