# Infraestrutura AWS - WordPress
Este repositório contém a infraestrutura como código para a criação de um ambiente WordPress na AWS. A arquitetura foi configurada de forma a garantir alta disponibilidade, escalabilidade e segurança.

## Siga os passos para realizar a implementação:

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

Implantação de instância de banco de dados Single-AZ (1 instância)

Instance Type: t3.micro.

Remover SG default e selecionar SG-RDS

Acesso: Restrito apenas às instâncias EC2 através do SG-RDS.

## 4. EFS (Elastic File System)
Subnets: Selecionadas as subnets privadas (priv-a e priv-b).

Security Group: Associado ao SG-EFS.

## 5. IAM Role para Instâncias EC2
Tipo de Entidade: EC2.

Permissões: EC2FullAccess e AutoScalingFullAccess.

json: 
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "*"
    }
  ]
}


## 6. Launch Template

AMI: Ubuntu.

Instance Type: t3.micro.

Security Group: SG-EC2.

Tags de autenticação.

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

Criar Application Load Balancer.

Scheme: internet-facing.

Subnets: Selecionadas as duas subnets públicas (pub-a, pub-b).

Security Group: SG-ALB.

Listener: HTTP:80 com direcionamento para o Target Group (wordpress-tg).

## 10. Integrações

EC2-> ASG-> Integrações-> Integra o LB criado ao ASG

## 12. Criar Bastion host

Tipo de instância: Ubuntu.

Habilitar ip público.

SG-Bastion

## 11. Teste e Validação

Aguarde o ASG lançar as instâncias.

Verifique a saúde das instâncias no Target Group.

Obtenha o DNS do ALB.

Acesse a URL no navegador (ex.: wordpress-alb-xxxx.elb.amazonaws.com) para visualizar a tela de instalação do WordPress.

## Recomendações de Teste Adicionais:
Termine uma instância manualmente: Verifique se o ASG cria uma nova instância para manter a capacidade desejada.

Faça upload de uma imagem, poste algo: Valide a persistência de dados. O novo tema deve estar disponível em todas as instâncias devido ao uso do EFS.

O EFS realmente contém os arquivos de mídia. Ou seja, se uma instância cair, outra pega os mesmos dados no EFS

Verifique o banco de dados: Confirme se as tabelas do WordPress estão sendo criadas no banco de dados RDS.

## Opcional: Aumento de tráfego simulado para testar ASG

Simulação de requisições:

Configurar na política do ASG: diminui a tolerância para >40% de uso da CPU (só para fins didáticos)

Em sua distribuição local, rode:

sudo apt-get update
sudo apt-get install apache2-utils -y

while true; do ab -n 5000 -c 50 http://wordpress-lb-307024714.us-east-1.elb.amazonaws.com/; done

<img width="1600" height="230" alt="image" src="https://github.com/user-attachments/assets/0c953dff-2a78-42a3-af78-adc48aba24b3" />

Assim, Podemos ver que o Auto Scaling funciona na medida que criou outras instâncias ao sobrecarregarmos o uso da CPU através de requisições simuladas.

<img width="1731" height="214" alt="image" src="https://github.com/user-attachments/assets/8c3a1910-4359-4590-a38a-cadbd772138e" />

Após algum tempo depois da simulação, podemos observar que as instâncias são desalocadas. Assim, o sistema se adequa automaticamente e garante que não haverá queda do serviço.


