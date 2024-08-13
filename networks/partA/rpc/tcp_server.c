#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <arpa/inet.h>
#include <unistd.h>

int main()
{
    int sockfds = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (sockfds < 0)
    {
        printf("Error in Socket\n");
        exit(1);
    }
    struct sockaddr_in ServerAddressA, ServerAddressB, ClientAddressA, ClientAddressB;
    ServerAddressA.sin_family = AF_INET;
    ServerAddressA.sin_port = htons(5100);
    ServerAddressA.sin_addr.s_addr = htonl(INADDR_ANY);
    int status = bind(sockfds, (struct sockaddr *)&ServerAddressA, sizeof(ServerAddressA));
    if (status == -1)
    {
        printf("Error in Bind\n");
        exit(1);
    }
    int sockfdsB = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (sockfdsB < 0)
    {
        printf("Error in Socket\n");
        exit(1);
    }
    ServerAddressB.sin_family = AF_INET;
    ServerAddressB.sin_port = htons(5566);
    ServerAddressB.sin_addr.s_addr = htonl(INADDR_ANY);
    int statusB = bind(sockfdsB, (struct sockaddr *)&ServerAddressB, sizeof(ServerAddressB));
    if (statusB == -1)
    {
        printf("Error in Bind\n");
        exit(1);
    }
    if (listen(sockfds, 6) == -1)
    {
        printf("Error in listen\n");
        exit(1);
    }
    if (listen(sockfdsB, 6) == -1)
    {
        printf("Error in listen\n");
        exit(1);
    }
    while (1)
    {
        int ClientLengthA = sizeof(ClientAddressA);
        bzero((char *)&ClientAddressA, ClientLengthA);
        int TransSockA = accept(sockfds, (struct sockaddr *)&ClientAddressA, &ClientLengthA);
        if (TransSockA < 0)
        {
            printf("Error in Accept\n");
            exit(1);
        }
        int ClientLengthB = sizeof(ClientAddressB);
        bzero((char *)&ClientAddressB, ClientLengthB);
        int TransSockB = accept(sockfdsB, (struct sockaddr *)&ClientAddressB, &ClientLengthB);
        if (TransSockB < 0)
        {
            printf("Error in Accept\n");
            exit(1);
        }
        while (1)
        {
            char BufferA[10];
            bzero(BufferA, 10);
            int ount = recv(TransSockA, BufferA, sizeof(BufferA), 0);
            if (ount == -1)
            {
                printf("Error in Recieving\n");
                exit(1);
            }
            char BufferB[10];
            bzero(BufferB, 10);
            int cont = recv(TransSockB, BufferB, sizeof(BufferB), 0);
            if (cont == -1)
            {
                printf("Error in Recieving\n");
                exit(1);
            }
            int ValA = atoi(BufferA);
            int ValB = atoi(BufferB);
            if (ValA == ValB)
            {
                strcpy(BufferA, "Draw\n");
                int cunt = send(TransSockA, BufferA, 10, 0);
                if (cunt == -1)
                {
                    printf("Error in Sending\n");
                    exit(1);
                }
                strcpy(BufferB, "Draw\n");
                int cent = send(TransSockB, BufferB, 10, 0);
                if (cent == -1)
                {
                    printf("Error in Sending\n");
                    exit(1);
                }
            }
            else if (ValA == 1 + ValB)
            {
                strcpy(BufferA, "Lost\n");
                int cunt = send(TransSockA, BufferA, 10, 0);
                if (cunt == -1)
                {
                    printf("Error in Sending\n");
                    exit(1);
                }
                strcpy(BufferB, "Win\n");
                int cent = send(TransSockB, BufferB, 10, 0);
                if (cent == -1)
                {
                    printf("Error in Sending\n");
                    exit(1);
                }
            }
            else if (ValB == ValA + 1)
            {
                strcpy(BufferA, "Win\n");
                int cunt = send(TransSockA, BufferA, 10, 0);
                if (cunt == -1)
                {
                    printf("Error in Sending\n");
                    exit(1);
                }
                strcpy(BufferB, "Lost\n");
                int cent = send(TransSockB, BufferB, 10, 0);
                if (cent == -1)
                {
                    printf("Error in Sending\n");
                    exit(1);
                }
            }
            else if (ValA == ValB + 2)
            {
                strcpy(BufferA, "Win\n");
                int cunt = send(TransSockA, BufferA, 10, 0);
                if (cunt == -1)
                {
                    printf("Error in Sending\n");
                    exit(1);
                }
                strcpy(BufferB, "Lost\n");
                int cent = send(TransSockB, BufferB, 10, 0);
                if (cent == -1)
                {
                    printf("Error in Sending\n");
                    exit(1);
                }
            }
            else if (ValB == ValA + 2)
            {
                strcpy(BufferA, "Lost\n");
                int cunt = send(TransSockA, BufferA, 10, 0);
                if (cunt == -1)
                {
                    printf("Error in Sending\n");
                    exit(1);
                }
                strcpy(BufferB, "Win\n");
                int cent = send(TransSockB, BufferB, 10, 0);
                if (cent == -1)
                {
                    printf("Error in Sending\n");
                    exit(1);
                }
            }
            bzero(BufferA, 10);
            int count = recv(TransSockA, BufferA, sizeof(BufferA), 0);
            if (count == -1)
            {
                printf("Error in Recieving\n");
                exit(1);
            }
            bzero(BufferB, 10);
            int cot = recv(TransSockB, BufferB, sizeof(BufferB), 0);
            if (cot == -1)
            {
                printf("Error in Recieving\n");
                exit(1);
            }
            if (!strcmp(BufferA, "n") || !strcmp(BufferB, "n"))
            {
                strcpy(BufferA, "Close\n");
                int cunt = send(TransSockA, BufferA, 10, 0);
                if (cunt == -1)
                {
                    printf("Error in Sending\n");
                    exit(1);
                }
                strcpy(BufferB, "Close\n");
                int cent = send(TransSockB, BufferB, 10, 0);
                if (cent == -1)
                {
                    printf("Error in Sending\n");
                    exit(1);
                }
                break;
            }
            else
            {
                strcpy(BufferA, "Start");
                int cunt = send(TransSockA, BufferA, 10, 0);
                if (cunt == -1)
                {
                    printf("Error in Sending\n");
                    exit(1);
                }
                strcpy(BufferB, "Start");
                int cent = send(TransSockB, BufferB, 10, 0);
                if (cent == -1)
                {
                    printf("Error in Sending\n");
                    exit(1);
                }
            }
        }
        int closureA = close(TransSockA);
        if (closureA == -1)
        {
            printf("Closing Socket Failed");
            exit(1);
        }
        int closureB = close(TransSockB);
        if (closureB == -1)
        {
            printf("Closing Socket Failed");
            exit(1);
        }
    }
    int closure = close(sockfds);
    if (closure == -1)
    {
        printf("Closing Socket Failed");
        exit(1);
    }
}