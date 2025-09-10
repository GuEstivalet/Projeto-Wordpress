# Infraestrutura AWS - WordPress
Este repositório contém a infraestrutura como código para a criação de um ambiente WordPress na AWS. A arquitetura foi configurada de forma a garantir alta disponibilidade, escalabilidade e segurança.

## 1. Virtual Private Cloud (VPC)
VPC personalizada com sub-redes públicas e privadas.

2 Subnets Públicas

2 Subnets Privadas

Configuração automática de tabelas de rotas, Internet Gateway (IGW), NAT Gateways e IPs Elásticos.

Tabelas de Rotas:

rtb-pub: Rota padrão 0.0.0.0/0 para o IGW.

rtb-priv (Subnet 1): Rota padrão 0.0.0.0/0 para o NAT Gateway 1.

rtb-priv (Subnet 2): Rota padrão 0.0.0.0/0 para o NAT Gateway 2.

## 2. Grupos de Segurança (Security Groups - SGs)
SG-ALB:

Inbound: TCP 80 de 0.0.0.0/0.

Outbound: All traffic para 0.0.0.0/0.

SG-Bastion:

Inbound: TCP 22 de My IP.

Outbound: All traffic para 0.0.0.0/0.

SG-EC2:

Inbound:

TCP 80 do SG-ALB.

TCP 22 do SG-Bastion.

Outbound: All traffic para 0.0.0.0/0.

SG-RDS:

Inbound: TCP 3306 do SG-EC2.

Outbound: All traffic para 0.0.0.0/0.

SG-EFS:

Inbound: TCP 2049 do SG-EC2.

Outbound: All traffic para 0.0.0.0/0.

## 3. RDS (Relational Database Service)
DB Subnet Group: Configurado em 2 Zonas de Disponibilidade, utilizando as subnets privadas (priv-a e priv-b).

RDS Instance:

Engine: MySQL.

Instance Type: t3.micro.

Acesso: Restrito apenas às instâncias EC2 através do SG-EC2.

## 4. EFS (Elastic File System)
Subnets: Selecionadas as subnets privadas (priv-a e priv-b).

Security Group: Associado ao SG-EFS.

## 5. IAM Role para Instâncias EC2
Tipo de Entidade: EC2.

Permissões: EC2FullAccess e AutoScalingFullAccess.

## 6. Launch Template
Tags:

Name = wordpress-ec2

Project = Wordpress-Project

CostCenter = DevSecOpsLab

AMI: Ubuntu.

Instance Type: t3.micro.

Security Group: SG-EC2.

Detalhes Avançados: Associado à AMI Role criada e inclui um script de User Data para configuração automática das instâncias.

## 7. Target Group
Tipo de Alvo: Instâncias.

Protocolo: HTTP na porta 80.

VPC: Associado à VPC criada.

Health Checks:

Protocolo: HTTP.

Caminho: /.

## 8. Auto Scaling Group (ASG)
Subnets: Selecionadas as subnets privadas (priv-a e priv-b).

Load Balancer: Anexado ao Target Group existente.

Capacidade Desejada: 2 instâncias.

Capacidade Mínima: 1 instância.

Capacidade Máxima: 3 instâncias.

Política de Escalonamento: Baseada na Utilização da CPU (ex.: > 70%).

Health Check: Tipo ELB.

## 9. Application Load Balancer (ALB)
Scheme: internet-facing.

Subnets: Selecionadas as duas subnets públicas (pub-a, pub-b).

Security Group: SG-ALB.

Listener: HTTP:80 com direcionamento para o Target Group (wordpress-tg).

## 10. Teste e Validação
Aguarde o ASG lançar as instâncias.

Verifique a saúde das instâncias no Target Group.

Obtenha o DNS do ALB.

Acesse a URL no navegador (ex.: wordpress-alb-xxxx.elb.amazonaws.com) para visualizar a tela de instalação do WordPress.

Recomendações de Teste Adicionais:
Termine uma instância manualmente: Verifique se o ASG cria uma nova instância para manter a capacidade desejada.

Faça upload de um tema ou plugin: Valide a persistência de dados. O novo tema deve estar disponível em todas as instâncias devido ao uso do EFS.

Verifique o banco de dados: Confirme se as tabelas do WordPress estão sendo criadas no banco de dados RDS.
