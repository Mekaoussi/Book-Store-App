import 'package:flutter/material.dart';

Widget buildcomment() {
  return Padding(
    padding: const EdgeInsets.only(left: 15, right: 15, bottom: 0),
    child: Container(
      decoration: BoxDecoration(
          color: const Color.fromARGB(255, 200, 200, 200),
          borderRadius: BorderRadius.circular(15)),
      width: double.infinity,
      height: 90,
      child: const Padding(
        padding: EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  "Comments",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 15, 15, 15)),
                ),
                Text(
                  '  1.6K',
                  style: TextStyle(color: Color.fromARGB(255, 70, 70, 70)),
                )
              ],
            ),
            Padding(
              padding: EdgeInsets.only(top: 5),
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 5, right: 10),
                    child: CircleAvatar(
                      radius: 15,
                      backgroundImage: AssetImage('assets/images/me.jpg'),
                    ),
                  ),
                  Text(
                    overflow: TextOverflow.ellipsis,
                    'i really liked the ending it was epic !',
                    style: TextStyle(color: Color.fromARGB(255, 30, 30, 30)),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    ),
  );
}
