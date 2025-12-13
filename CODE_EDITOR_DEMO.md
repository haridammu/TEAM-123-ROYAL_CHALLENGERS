# Code Editor Feature Documentation

## Overview
The Code Editor feature allows users to write, execute, and save code snippets in multiple programming languages directly within the LMS application. This feature integrates with a backend code execution service to securely compile and run user code.

## Supported Languages
- Python
- Java
- C
- C++
- JavaScript
- Dart

## Features

### 1. Language Selection
- Dropdown menu to select the programming language
- Each language comes with a default "Hello, World!" example

### 2. Code Editing
- Full-featured text editor for writing code
- Syntax highlighting compatible with monospace fonts
- Ability to write multi-line programs

### 3. Code Execution
- Run button to execute code snippets
- Real-time output display in console-style window
- Error handling for compilation and runtime errors
- Loading indicator during execution

### 4. Code Management
- Save snippets with custom titles
- Clear code editor
- Load default examples for each language

## How to Use

### Running Code
1. Select a programming language from the dropdown
2. Write or modify code in the editor area
3. Click the "Run Code" button
4. View output in the console section below

### Saving Snippets
1. Write your code in the editor
2. Click the "Save" button or the save option in the menu
3. Enter a title for your snippet when prompted
4. Your snippet will be saved to your account

### Managing Code
- Use the menu (three dots) in the top right corner for additional options:
  - Clear Code: Erase all code in the editor
  - Load Default Code: Reset to the default example for the selected language
  - Save Snippet: Save your current code with a title

## Technical Details

### Backend Integration
The code editor communicates with a Django backend service that:
- Securely executes code in isolated environments
- Supports multiple programming languages
- Implements timeout protection (30 seconds)
- Handles compilation and runtime errors
- Requires authentication for all operations

### Security Features
- Isolated execution environments
- Time-limited executions
- Restricted file system access
- Authentication required for all operations

## Troubleshooting

### Common Issues
1. **"Network error" message**: Ensure the backend service is running and accessible
2. **"Authentication failed"**: Log out and log back in to refresh your token
3. **Empty output**: Check if your code produces output (e.g., print statements)
4. **Compilation errors**: Review syntax and language-specific requirements

### Requirements
- Active internet connection
- Valid authentication token
- Backend code execution service running

## Future Enhancements
- Retrieve and manage saved snippets
- Syntax highlighting
- Auto-completion
- Collaboration features
- Code templates and examples