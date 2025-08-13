#!/usr/bin/env python3.13
"""
Python 3.13 verification script for Jump Server
Tests Python installation and key packages
"""

import sys
import platform
import subprocess
from pathlib import Path

def test_python_version():
    """Test Python version"""
    print("🐍 Python Version Information")
    print("=" * 40)
    print(f"Python Version: {sys.version}")
    print(f"Platform: {platform.platform()}")
    print(f"Architecture: {platform.architecture()}")
    print(f"Python Executable: {sys.executable}")
    
    # Check if we're running Python 3.13
    if sys.version_info >= (3, 13):
        print("✅ Python 3.13+ detected!")
    else:
        print("❌ Python version is older than 3.13")
        return False
    
    return True

def test_packages():
    """Test key Python packages"""
    print("\n📦 Package Testing")
    print("=" * 40)
    
    packages = [
        'requests',
        'httpx', 
        'websockets',
        'fastapi',
        'uvicorn',
        'mcp',
        'ollama',
        'pytest',
        'jupyter',
        'ipython'
    ]
    
    failed_packages = []
    
    for package in packages:
        try:
            __import__(package)
            print(f"✅ {package}")
        except ImportError as e:
            print(f"❌ {package} - {e}")
            failed_packages.append(package)
    
    if failed_packages:
        print(f"\n❌ Failed packages: {', '.join(failed_packages)}")
        return False
    else:
        print("\n✅ All packages installed successfully!")
        return True

def test_pip():
    """Test pip functionality"""
    print("\n📋 Pip Information")
    print("=" * 40)
    
    try:
        result = subprocess.run([sys.executable, '-m', 'pip', '--version'], 
                              capture_output=True, text=True)
        print(f"Pip version: {result.stdout.strip()}")
        
        # Test pip list
        result = subprocess.run([sys.executable, '-m', 'pip', 'list'], 
                              capture_output=True, text=True)
        packages = result.stdout.strip().split('\n')[2:]  # Skip header
        print(f"Installed packages: {len(packages)}")
        
        return True
    except Exception as e:
        print(f"❌ Pip test failed: {e}")
        return False

def test_environment():
    """Test environment setup"""
    print("\n🔧 Environment Testing")
    print("=" * 40)
    
    # Test workspace
    workspace = Path('/root')
    print(f"Workspace: {workspace}")
    print(f"Workspace exists: {workspace.exists()}")
    
    # Test common tools
    tools = ['curl', 'jq', 'git', 'vim', 'node']
    for tool in tools:
        try:
            result = subprocess.run(['which', tool], capture_output=True, text=True)
            if result.returncode == 0:
                print(f"✅ {tool}: {result.stdout.strip()}")
            else:
                print(f"❌ {tool}: not found")
        except Exception as e:
            print(f"❌ {tool}: error - {e}")

def main():
    """Main test function"""
    print("🧪 Jump Server Python 3.13 Verification")
    print("=" * 50)
    
    success = True
    
    # Run all tests
    success &= test_python_version()
    success &= test_packages()
    success &= test_pip()
    test_environment()
    
    print("\n" + "=" * 50)
    if success:
        print("✅ All tests passed! Python 3.13 environment is ready! 🎉")
        print("\nQuick start commands:")
        print("  python --version     # Check Python version")
        print("  pip list            # List installed packages")
        print("  ./test-services.sh  # Test service connectivity")
    else:
        print("❌ Some tests failed. Please check the installation.")
    
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())
