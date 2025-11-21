# Security Best Practices

## Overview

This document outlines security best practices for deploying and using the NiFi REST API automation tools. **The default configuration is designed for development only and must be hardened for production use.**

---

## Critical Security Warnings

### 1. SSL Certificate Verification

**Issue**: SSL verification is disabled by default for development convenience.

**Risk**: Man-in-the-middle attacks, credential interception

**Production Fix**:
```python
# Enable SSL verification in production
client = NiFiClient(
    base_url="https://nifi.production.com:8443",
    username="admin",
    password=os.environ["NIFI_PASSWORD"],
    verify_ssl=True,  # Enable verification
    cert_path="/path/to/ca-bundle.crt"  # Or provide CA bundle
)
```

**Shell Scripts**: Modify scripts to remove `-k` flag from curl commands in production.

### 2. Default Credentials

**Issue**: Default password `adminadminadmin` is widely known.

**Risk**: Unauthorized access, data breaches

**Production Fix**:
1. Change password immediately after setup
2. Use strong passwords (20+ characters, mixed case, numbers, symbols)
3. Never commit `.env` file to version control
4. Rotate credentials regularly (every 90 days minimum)
5. Set restrictive file permissions:
```bash
chmod 600 .env
```

### 3. Credentials in Command Line

**Issue**: Shell scripts pass passwords via command line, visible in process list

**Risk**: Password exposure in `ps` output, shell history, logs

**Mitigation**:
- Use environment variables instead of `.env` sourcing
- Consider using encrypted credential stores
- Clear shell history after use: `history -c`
- Use heredoc for sensitive data in production scripts

### 4. Token Exposure in Logs

**Issue**: Scripts print partial JWT tokens to console

**Risk**: Token leakage in logs, potential unauthorized access

**Production Fix**:
- Remove token printing from scripts
- Implement proper logging with sensitive data filtering
- Use log aggregation with access controls

---

## Production Deployment Checklist

### Before Production Deployment

- [ ] Change all default credentials
- [ ] Enable SSL certificate verification
- [ ] Use production-grade certificates (not self-signed)
- [ ] Set `.env` file permissions to 600
- [ ] Remove `.env` from version control
- [ ] Audit git history for exposed credentials
- [ ] Implement credential rotation policy
- [ ] Enable HTTPS only (reject HTTP)
- [ ] Configure firewall rules (restrict NiFi port access)
- [ ] Enable audit logging
- [ ] Implement rate limiting
- [ ] Set up monitoring and alerting
- [ ] Document incident response procedures
- [ ] Perform security testing (penetration test)

### Environment-Specific Configuration

**Development**:
```bash
NIFI_URL=https://localhost:8443
NIFI_USERNAME=admin
NIFI_PASSWORD=dev_password_min_12_chars
```

**Production**:
```bash
NIFI_URL=https://nifi.prod.internal:8443
NIFI_USERNAME=automation_svc_account
NIFI_PASSWORD=<strong-random-password>
# Store in secrets manager (Vault, AWS Secrets Manager, etc.)
```

---

## Secure Credential Management

### Recommended Approach

1. **Use Secrets Manager**
```python
import boto3  # AWS example

def get_nifi_credentials():
    client = boto3.client('secretsmanager')
    secret = client.get_secret_value(SecretId='prod/nifi/credentials')
    creds = json.loads(secret['SecretString'])
    return creds['username'], creds['password']

username, password = get_nifi_credentials()
nifi_client = NiFiClient(base_url=NIFI_URL, username=username, password=password)
```

2. **Environment Variables Only** (Better than `.env` file)
```bash
export NIFI_URL="https://nifi.prod.internal:8443"
export NIFI_USERNAME="svc_nifi"
export NIFI_PASSWORD="$(vault kv get -field=password secret/nifi)"
```

3. **Encrypted Configuration Files**
```bash
# Encrypt .env file
ansible-vault encrypt .env

# Use in scripts
ansible-vault view .env | grep NIFI_PASSWORD
```

---

## Network Security

### TLS/SSL Configuration

**Minimum TLS Version**: TLS 1.2 or higher

**Recommended Cipher Suites**:
- TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
- TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256

**Certificate Requirements**:
- Use certificates from trusted CA
- Enable certificate validation in production
- Implement certificate pinning for critical systems
- Monitor certificate expiration

### Firewall Rules

```bash
# Allow only specific IPs to access NiFi API
iptables -A INPUT -p tcp --dport 8443 -s 10.0.0.0/8 -j ACCEPT
iptables -A INPUT -p tcp --dport 8443 -j DROP
```

### Network Segmentation

- Deploy NiFi in isolated network segment
- Use bastion hosts for administrative access
- Implement VPN for remote access
- Restrict outbound connections

---

## Access Control

### Principle of Least Privilege

1. Create service accounts with minimal permissions
2. Avoid using `admin` account for automation
3. Grant only required API permissions
4. Implement role-based access control (RBAC)

### Authentication Best Practices

- Use strong passwords (20+ characters)
- Implement multi-factor authentication (MFA) where possible
- Set session timeouts appropriately
- Monitor for brute force attempts
- Implement account lockout policies

### Token Management

**JWT Token Security**:
- Tokens expire after 8 hours by default
- Store tokens securely (not in files or logs)
- Implement token refresh before expiration
- Clear tokens from memory after use

```python
class SecureNiFiClient(NiFiClient):
    def __del__(self):
        # Clear token on object destruction
        if self.token:
            self.token = None
```

---

## Audit and Monitoring

### Logging Requirements

**What to Log**:
- Authentication attempts (success and failure)
- API requests with timestamps
- Configuration changes
- Error conditions
- Access patterns

**What NOT to Log**:
- Passwords or tokens
- Full API responses containing sensitive data
- Personal identifiable information (PII)

### Monitoring Alerts

Set up alerts for:
- Failed authentication attempts (>5 in 5 minutes)
- Unusual API access patterns
- Certificate expiration (30 days warning)
- Error rate spikes
- Unauthorized access attempts

---

## Vulnerability Management

### Keep Software Updated

```bash
# Regularly update dependencies
pip install --upgrade -r requirements.txt

# Check for known vulnerabilities
pip-audit
safety check
```

### Security Scanning

```bash
# Scan Python code for security issues
bandit -r nifi_client/

# Scan for secrets in code
trufflehog --regex --entropy=False .

# Check shell scripts
shellcheck scripts/*.sh
```

---

## Incident Response

### If Credentials Are Compromised

1. **Immediately**:
   - Rotate all affected credentials
   - Revoke active sessions/tokens
   - Review access logs for unauthorized activity
   - Disable compromised accounts

2. **Within 24 Hours**:
   - Conduct forensic analysis
   - Notify affected parties if required
   - Document incident timeline
   - Update security controls

3. **Follow-Up**:
   - Implement additional security measures
   - Conduct security training
   - Update incident response procedures
   - Perform lessons learned session

---

## Code Security Practices

### Input Validation

Always validate and sanitize inputs:

```python
import re
import uuid

def validate_processor_id(proc_id):
    """Validate processor ID is valid UUID."""
    try:
        uuid.UUID(proc_id)
        return True
    except ValueError:
        raise ValueError(f"Invalid processor ID: {proc_id}")

def validate_url(url):
    """Ensure URL uses HTTPS."""
    if not url.startswith('https://'):
        raise ValueError("Only HTTPS URLs are allowed")
    return url
```

### Parameterized Queries

Never build JSON/URLs with string concatenation:

```python
# BAD
json_str = f'{{"name": "{user_input}"}}'

# GOOD
data = {"name": user_input}
response = client.post("/endpoint", data)
```

---

## Compliance Considerations

### Data Privacy

- Minimize collection of PII
- Implement data retention policies
- Encrypt sensitive data at rest and in transit
- Document data flows

### Regulatory Compliance

Consider requirements for:
- GDPR (EU)
- HIPAA (Healthcare - US)
- PCI DSS (Payment data)
- SOC 2
- ISO 27001

---

## Additional Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [CIS Controls](https://www.cisecurity.org/controls)
- [Apache NiFi Security Documentation](https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#security-configuration)

---

## Reporting Security Issues

If you discover a security vulnerability:

1. **DO NOT** open a public GitHub issue
2. Email security concerns to: [your-security-email@example.com]
3. Include:
   - Description of vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

We aim to respond within 48 hours and provide a fix within 30 days for critical issues.

---

## Security Policy Version

- **Version**: 1.0
- **Last Updated**: 2025-01-21
- **Next Review**: 2025-04-21 (quarterly review)

---

**Remember**: Security is an ongoing process, not a one-time setup. Regularly review and update your security practices.
