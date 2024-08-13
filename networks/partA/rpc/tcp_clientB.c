#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <arpa/inet.h>
#include <unistd.h>

int main()
{
    int sockfdc = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (sockfdc < 0)
    {
        printf("Error in Socket\n");
        exit(1);
    }
    struct sockaddr_in ServerAddressPort;
    ServerAddressPort.sin_family = AF_INET;
    ServerAddressPort.sin_port = htons(5566);
    ServerAddressPort.sin_addr.s_addr = inet_addr("127.0.0.1");
    if (connect(sockfdc, (struct sockaddr *)&ServerAddressPort, sizeof(ServerAddressPort)) == -1)
    {
        printf("Error in Connect\n");
        exit(1);
    }
    char Buffer[10] = "Start";
    int flag = 0;
    while (!strcmp(Buffer, "Start"))
    {
        bzero(Buffer, sizeof(Buffer));
        printf("Choose One : Rock :- 0\n\t Scissors :- 1 \n\t Paper :- 2\n ");
        scanf("%s", Buffer);
        int cunt = send(sockfdc, Buffer, sizeof(Buffer), 0);
        if (cunt == -1)
        {
            printf("Error in Sending\n");
            exit(1);
        }
        bzero(Buffer, 10);
        int count = recv(sockfdc, Buffer, sizeof(Buffer), 0);
        if (count == -1)
        {
            printf("Error in Recieving\n");
            exit(1);
        }
        printf("%s\n", Buffer);
        printf("Do you want to play again[y/n]\n");
        bzero(Buffer, sizeof(Buffer));
        scanf("%s", Buffer);
        if (!strcmp(Buffer, "n") || !strcmp(Buffer, "N"))
        {
            flag++;
        }
        int cont = send(sockfdc, Buffer, sizeof(Buffer), 0);
        if (cont == -1)
        {
            printf("Error in Sending\n");
            exit(1);
        }
        bzero(Buffer, 10);
        int cent = recv(sockfdc, Buffer, sizeof(Buffer), 0);
        if (cent == -1)
        {
            printf("Error in Recieving\n");
            exit(1);
        }
    }
    if (flag == 0)
    {
        printf("Sorry! The other player doesn't wanna play again\n");
    }
    int closure = close(sockfdc);
    if (closure == -1)
    {
        printf("Closing Socket Failed");
        exit(1);
    }
}