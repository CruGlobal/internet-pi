<!-- this is a first draft of a write up of this project. To be posted on my portfolio and medium -->

# Building a Comprehensive Internet Monitoring System with Raspberry Pi

Geerling put together most of these parts, however there were a few missing elements critical to our use case:
Sending the collected metrics from multiple devices to a single location. Solution https://github.com/roguisharcanetrickster/custom-metrics
Keeping the distributed nodes up to date (system service)
initial install (scripts)

the install is still a work in progress.

## Introduction
- Brief overview of the project
- Why I built this (a global organizatoin needs to quantify proplematic internet at remote locations)
- What makes this different from existing solutions (wants to use bigqury and powerbi. I however, decided early on that actually implementing the powerbi interface was outside the scope of what I could work on efficiently)

## The Problem
- Need for comprehensive internet monitoring (speed, uptime, ping)
- Existing solutions were either too complex or too limited
- Wanting to combine multiple monitoring tools in one system
- Need for long-term data storage and analysis

## The Solution: Internet Pi
- Raspberry Pi-based monitoring system
- Combines multiple open-source tools
- Automated deployment with Ansible
- BigQuery integration for long-term data storage

## Technical Architecture

### Core Components
- **Custom Metrics Service**: BigQuery integration
- **Prometheus**: Metrics collection and storage
- **Speedtest Exporter**: Internet speed monitoring
- **Blackbox Exporter**: Uptime and ping monitoring

### Infrastructure
- Docker containers for easy deployment
- Ansible for configuration management
- GitHub Actions for CI/CD development. unsuitable for production. (why?)
- Systemd service for auto-updates

### Data Flow
- Prometheus scrapes metrics from various exporters
- Custom metrics service pushes data to BigQuery
- data visualized in looker studio.

## Key Features

### Internet Monitoring
- Real-time speed tests
- Ping latency tracking
- Uptime monitoring
- Historical data analysis

### Data Analytics
- BigQuery integration for long-term storage
- Custom dashboards
- Performance trend analysis
- Automated reporting

### Automation
- One-command deployment
- Auto-updates via GitHub Actions
- Self-healing containers
- Configuration management

## Implementation Details

### Setup Process
- Clone repository
- Run configuration script
- Automated BigQuery setup
- One-command installation

### Configuration Management
- YAML-based configuration
- Environment-specific settings
- Secure credential management
- Template-based deployment

### Monitoring Stack
- Container health checks
- Service status monitoring
- Automated restarts
- Performance metrics

## Results and Benefits

### Performance Improvements
- Network-wide ad-blocking
- Reduced bandwidth usage
- Better network visibility

### Operational Benefits
- Automated maintenance
- Centralized monitoring
- Historical data analysis
- Proactive issue detection

### Cost Savings
- Open-source tools
- Low-power Raspberry Pi
- Reduced bandwidth costs
- Minimal maintenance overhead

## Technical Challenges and Solutions

### Challenge 1: Breaking dns on install
  DNS would break with running the playbook. fix was to make sure that the resolv.conf was safe
 `Check if /etc/resolv.conf is a symlink (systemd-resolved)`

### Challenge 2: Data Persistence
- **Problem**: Long-term data storage
- **Solution**: BigQuery integration with custom metrics service
had to make a personal account since I lacked organization access. The organizational momentum to support this project did not exist until there was a proof of concept
the data also has to be useful for visualizatoin. a unique id for each pi, and only send a single record every five minutes. The initial version had 10,000 records in a single night.

### Challenge 3: Automated Deployment
- **Problem**: Complex setup process
- **Solution**: Ansible playbooks with GitHub Actions CI/CD

### Challenge 4: Configuration Management
- **Problem**: Managing credentials and settings
- **Solution**: Interactive setup script with secure defaults
Still not great.

## Lessons Learned

### Infrastructure as Code
- Benefits of using Ansible for configuration
- Version control for infrastructure
- Automated testing and deployment saves time.

### Data Architecture
- Cost optimization strategies

## Future Enhancements

### Planned Features
simplify install

### Scalability Considerations
- Multi-site monitoring

## Conclusion
- Summary of achievements
- Value of the solution
- Encouragement for others to build similar systems

## Resources
- GitHub repository link
- Documentation
- Community contributions
- Related projects and tools
