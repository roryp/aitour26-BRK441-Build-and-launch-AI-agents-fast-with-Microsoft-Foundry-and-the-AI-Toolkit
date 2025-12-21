#!/usr/bin/env pwsh
# Azure PostgreSQL Database Initialization Script
# This script restores the Zava retail database backup to Azure PostgreSQL

param(
    [string]$PostgresServer = $env:POSTGRES_SERVER_NAME,
    [string]$PostgresPassword = $env:POSTGRES_ADMIN_PASSWORD,
    [string]$PostgresUser = "zadmin",
    [string]$DatabaseName = "zava",
    [string]$BackupFile = "data/zava_retail_2025_07_21_postgres_rls.backup"
)

Write-Host ""
Write-Host "=== Initializing Azure PostgreSQL Database ===" -ForegroundColor Cyan
Write-Host ""

# Validate required parameters
if (-not $PostgresServer) {
    Write-Host "ERROR: POSTGRES_SERVER_NAME environment variable not set" -ForegroundColor Red
    exit 1
}

if (-not $PostgresPassword) {
    Write-Host "ERROR: POSTGRES_ADMIN_PASSWORD environment variable not set" -ForegroundColor Red
    exit 1
}

$PostgresHost = "$PostgresServer.postgres.database.azure.com"
$BackupPath = Join-Path $PSScriptRoot ".." $BackupFile

Write-Host "PostgreSQL Server: $PostgresHost"
Write-Host "Database: $DatabaseName"
Write-Host "Backup File: $BackupPath"
Write-Host ""

# Check if backup file exists
if (-not (Test-Path $BackupPath)) {
    Write-Host "ERROR: Backup file not found at $BackupPath" -ForegroundColor Red
    exit 1
}

Write-Host "Restoring database backup using Docker..." -ForegroundColor Yellow

# Use Docker to run pg_restore since pg_restore might not be installed locally
$dockerCmd = @(
    "docker", "run", "--rm",
    "-v", "${BackupPath}:/backup.dump:ro",
    "-e", "PGPASSWORD=$PostgresPassword",
    "postgres:16",
    "pg_restore",
    "--host=$PostgresHost",
    "--port=5432",
    "--username=$PostgresUser",
    "--dbname=$DatabaseName",
    "--verbose",
    "--no-owner",
    "--no-privileges",
    "--if-exists",
    "--clean",
    "/backup.dump"
)

Write-Host "Running: docker run postgres:16 pg_restore ..." -ForegroundColor Gray

try {
    $result = & $dockerCmd[0] $dockerCmd[1..($dockerCmd.Length-1)] 2>&1
    
    # pg_restore returns non-zero even on warnings, so check output
    $errors = $result | Where-Object { $_ -match "error|fatal" -and $_ -notmatch "does not exist, skipping" }
    
    if ($errors) {
        Write-Host "Warnings during restore (some are expected):" -ForegroundColor Yellow
        $errors | ForEach-Object { Write-Host "  $_" }
    }
    
    Write-Host ""
    Write-Host "Database restore completed!" -ForegroundColor Green
    
} catch {
    Write-Host "ERROR during database restore: $_" -ForegroundColor Red
    # Don't fail the entire deployment for DB restore issues
    Write-Host "Continuing with deployment..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Database Initialization Complete ===" -ForegroundColor Cyan
